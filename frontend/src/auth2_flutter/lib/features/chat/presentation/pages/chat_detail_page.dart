import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:auth2_flutter/features/chat/services/health_bot_service.dart';
import 'package:auth2_flutter/features/data/domain/presentation/cubits/auth_cubit.dart';
import 'dart:async';

class ChatDetailPage extends StatefulWidget {
  final String chatId;
  final String chatName;

  ChatDetailPage({super.key, required this.chatId, required this.chatName});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _healthData;
  bool _loadingHealth = true;
  bool _loadingMessages = true;
  String? _userName;
  final ScrollController _scrollController = ScrollController();
  bool _isBotTyping = false;
  Timer? _refreshTimer;
  String? _userId;
  final FocusNode _focusNode = FocusNode();

  bool get _isAssistant => widget.chatId == 'assistant';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthCubit>().currentUser;
      setState(() {
        _userName = user?.fullName ?? user?.email.split('@')[0] ?? 'there';
        _userId = user?.uid;
      });
      _loadMessages().then((_) {
        WidgetsBinding.instance.addPostFrameCallback((__) {
          _scrollToBottom();
        });
        if (_isAssistant) {
          _fetchHealthSummary(isInitialLoad: true);
        }
      });
    });

    if (_isAssistant) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) {
          _fetchHealthSummary(isInitialLoad: false);
        }
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _refreshTimer?.cancel();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  String _getBaseUrl() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    if (Platform.isIOS) return 'http://localhost:3001';
    return 'http://localhost:3001';
  }

  Future<void> _fetchHealthSummary({required bool isInitialLoad}) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${_getBaseUrl()}/api/user/health-summary'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'];
        final mappedData = {
          'todaySteps': data['steps'] ?? 0,
          'avgHeartRate': data['heartRate'] ?? 0,
          'todayCalories': data['calories'] ?? 0,
          'todaySleep': data['sleep'] ?? 0,
          'stepsGoal': data['stepsGoal'] ?? 6700,
        };

        setState(() {
          _healthData = mappedData;
          _loadingHealth = false;
        });
        
        if (isInitialLoad) {
          bool shouldAddWelcome = false;
          if (_messages.isEmpty) {
            shouldAddWelcome = true;
          } else {
            final lastMsg = _messages.last;
            if (lastMsg['fromMe'] == false && lastMsg['text'] == 'Hi $_userName! What can I help you with?') {
              setState(() {
                _messages.last['time'] = _getCurrentTime();
              });
              _saveMessages();
            } else {
              shouldAddWelcome = true;
            }
          }

          if (shouldAddWelcome) {
            setState(() {
              _messages.add({
                'fromMe': false,
                'text': 'Hi $_userName! What can I help you with?',
                'time': _getCurrentTime(),
              });
            });
            _saveMessages();
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      } else {
        if (isInitialLoad) setState(() => _loadingHealth = false);
      }
    } catch (e) {
      print('Error: $e');
      if (isInitialLoad) setState(() => _loadingHealth = false);
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _loadingMessages = true);
    try {
      if (_isAssistant) {
        final prefs = await SharedPreferences.getInstance();
        final key = 'chat_assistant_${_userId ?? ''}';
        final saved = prefs.getStringList(key);
        if (saved != null) {
          setState(() {
            _messages = saved.map((jsonStr) => jsonDecode(jsonStr) as Map<String, dynamic>).toList();
          });
        }
        setState(() => _loadingMessages = false);
      } else {
        final token = await _getToken();
        if (token == null) return;
        final response = await http.get(
          Uri.parse('${_getBaseUrl()}/api/chat/conversations/${widget.chatId}/messages'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          setState(() {
            _messages = List<Map<String, dynamic>>.from(json['data']);
            _loadingMessages = false;
          });
          await _markAsRead();
        } else {
          setState(() => _loadingMessages = false);
        }
      }
    } catch (e) {
      print('Error loading messages: $e');
      setState(() => _loadingMessages = false);
    }
  }

  Future<void> _markAsRead() async {
    if (_isAssistant) return;
    final token = await _getToken();
    if (token == null) return;
    try {
      final response = await http.post(
        Uri.parse('${_getBaseUrl()}/api/chat/conversations/${widget.chatId}/read'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  Future<void> _saveMessages() async {
    if (_isAssistant) {
      final prefs = await SharedPreferences.getInstance();
      final key = 'chat_assistant_${_userId ?? ''}';
      final messagesJson = _messages.map((msg) => jsonEncode(msg)).toList();
      await prefs.setStringList(key, messagesJson);
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.isEmpty || (_isAssistant && _healthData == null)) return;

    final timeText = _getCurrentTime();

    setState(() {
      _messages.add({'fromMe': true, 'text': text, 'time': timeText});
      if (_isAssistant) {
        _isBotTyping = true;
      }
    });
    _saveMessages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    if (_isAssistant) {
      final reply = await HealthBotService.getReply(text, _healthData!);
        if (!mounted) return;
        setState(() {
          _isBotTyping = false;
          _messages.add({'fromMe': false, 'text': reply, 'time': _getCurrentTime()});
        });
        _saveMessages();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
    } else {
      final token = await _getToken();
      if (token == null) return;
      try {
        final response = await http.post(
          Uri.parse('${_getBaseUrl()}/api/chat/conversations/${widget.chatId}/messages'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'text': text}),
        );
        if (response.statusCode == 200) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        } else {
          setState(() {
            _messages.removeLast();
          });
          final error = jsonDecode(response.body)['error'] ?? 'Failed to send message';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        }
      } catch (e) {
        print('Send error: $e');
        setState(() {
          _messages.removeLast();
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _handleSend() {
    String text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _sendMessage(text);
    _focusNode.requestFocus();
  }

  String _getCurrentTime() {
    final now = TimeOfDay.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _confirmClearChat() async {
    if (!_isAssistant) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          'Clear Conversation',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Text(
          'Are you sure you want to delete all messages?',
          style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _clearChat();
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
    });
    _saveMessages();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add({
        'fromMe': false,
        'text': 'Hi $_userName! What can I help you with?',
        'time': _getCurrentTime(),
      });
    });
    _saveMessages();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color background =
        isDark ? const Color(0xFF121212) : const Color(0xFFE6F5E6);
    final Color appBarTextColor = isDark ? Colors.white : Colors.black87;
    final Color inputFillColor =
        isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: appBarTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_isAssistant ? '🤖 ' : '', style: const TextStyle(fontSize: 18)),
            _isBotTyping
                ? Text(
                    'typing...',
                    style: TextStyle(
                      color: appBarTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  )
                : Text(
                    widget.chatName,
                    style: TextStyle(
                      color: appBarTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
          ],
        ),
        actions: [
          if (_isAssistant)
            IconButton(
              icon: Icon(Icons.delete, color: appBarTextColor),
              onPressed: _confirmClearChat,
            ),
        ],
      ),
      body: _loadingMessages || (_isAssistant && _loadingHealth)
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _buildMessageBubble(
                        text: msg['text'] ?? '',
                        time: msg['time'] ?? '',
                        fromMe: msg['fromMe'] == true,
                      );
                    },
                  ),
                ),
                if (_isAssistant && _isBotTyping)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildTypingIndicator(),
                  ),
                if (_isAssistant)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuickQuestion('📊 Health'),
                        _buildQuickQuestion('🚶 Steps'),
                        _buildQuickQuestion('😴 Sleep'),
                        _buildQuickQuestion('❤️ Heart'),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                  color: background,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          onSubmitted: (_) => _handleSend(),
                          style: TextStyle(
                            color: appBarTextColor,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.grey[500] : Colors.grey[600],
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: inputFillColor,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.send,
                          color: isDark ? Colors.green[300] : Colors.green[700],
                        ),
                        onPressed: _handleSend,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required String time,
    required bool fromMe,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color myBubbleColor =
        isDark ? const Color(0xFF1E3A5F) : Colors.blue[50]!;
    final Color otherBubbleColor =
        isDark ? const Color(0xFF1F1F1F) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color timeColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: fromMe
            ? const EdgeInsets.fromLTRB(80, 4, 0, 4)
            : const EdgeInsets.fromLTRB(0, 4, 80, 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        decoration: BoxDecoration(
          color: fromMe ? myBubbleColor : otherBubbleColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
              ),
              softWrap: true,
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: timeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickQuestion(String question) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ActionChip(
      label: Text(
        question,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      onPressed: () {
        _controller.text = question;
        _handleSend();
      },
    );
  }

  Widget _buildTypingIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.fromLTRB(0, 4, 80, 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTypingDot(0),
            const SizedBox(width: 4),
            _buildTypingDot(200),
            const SizedBox(width: 4),
            _buildTypingDot(400),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingDot(int delayMs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[400] : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}