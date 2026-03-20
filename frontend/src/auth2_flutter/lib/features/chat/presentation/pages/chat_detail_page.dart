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
  String? _userName;
  final ScrollController _scrollController = ScrollController();
  bool _isBotTyping = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthCubit>().currentUser;
      setState(() {
        _userName = user?.fullName ?? user?.email.split('@')[0] ?? 'there';
      });
      _loadMessages().then((_) {
        WidgetsBinding.instance.addPostFrameCallback((__) {
          _scrollToBottom();
        });
        _fetchHealthSummary(isInitialLoad: true);
      });
    });

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _fetchHealthSummary(isInitialLoad: false);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
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

  String _getCurrentTime() {
    final now = TimeOfDay.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    Color background = const Color(0xFFE6F5E6);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🤖 ', style: const TextStyle(fontSize: 18)),
            _isBotTyping
                ? const Text(
                    'typing...',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  )
                : Text(
                    widget.chatName,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.black87),
            onPressed: _confirmClearChat,
          ),
        ],
      ),
      body: _loadingHealth
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // messages
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

                // typing indicator
                if (_isBotTyping)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildTypingIndicator(),
                  ),

                // quick questions
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

                // input bar
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                  color: background,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          onSubmitted: (_) => _handleSend(),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.send, color: Colors.green[700]),
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
    return Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: fromMe
            ? const EdgeInsets.fromLTRB(80, 4, 0, 4)
            : const EdgeInsets.fromLTRB(0, 4, 80, 4),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          child: IntrinsicWidth(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              decoration: BoxDecoration(
                color: fromMe ? Colors.blue[50] : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    softWrap: true,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickQuestion(String question) {
    return ActionChip(
      label: Text(
        question,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      onPressed: () {
        _controller.text = question;
        _handleSend();
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.fromLTRB(0, 4, 80, 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
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
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  void _handleSend() {
    String text = _controller.text.trim();
    if (text.isEmpty || _healthData == null) return;

    final timeText = _getCurrentTime();

    setState(() {
      _messages.add({'fromMe': true, 'text': text, 'time': timeText});
      _isBotTyping = true;
    });
    _saveMessages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
    _controller.clear();

    final reply = HealthBotService.getReply(text, _healthData!);

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _isBotTyping = false;
        _messages.add({'fromMe': false, 'text': reply, 'time': _getCurrentTime()});
      });
      _saveMessages();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    });
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = _messages.map((msg) => jsonEncode(msg)).toList();
    await prefs.setStringList('chat_${widget.chatId}', messagesJson);
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('chat_${widget.chatId}');
    if (saved != null) {
      setState(() {
        _messages = saved.map((jsonStr) => jsonDecode(jsonStr) as Map<String, dynamic>).toList();
      });
    }
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Conversation'),
        content: const Text('Are you sure you want to delete all messages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
}