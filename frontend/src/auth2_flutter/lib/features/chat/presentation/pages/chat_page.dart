import 'package:auth2_flutter/features/chat/presentation/pages/chat_detail_page.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/appbar.dart';
import 'package:auth2_flutter/features/data/domain/presentation/cubits/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> _chats = [];
  bool _loading = true;
  String _searchText = '';
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = context.read<AuthCubit>().currentUser?.uid;
    _loadChats();
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

  Future<void> _loadChats() async {
    setState(() => _loading = true);
    try {
      final token = await _getToken();
      if (token == null) return;
      final response = await http.get(
        Uri.parse('${_getBaseUrl()}/api/chat/conversations'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        List<Map<String, dynamic>> sessions = List<Map<String, dynamic>>.from(json['data']);

        if (_currentUserId != null) {
          final prefs = await SharedPreferences.getInstance();
          final assistantMessages = prefs.getStringList('chat_assistant_$_currentUserId');
          if (assistantMessages != null && assistantMessages.isNotEmpty) {
            final lastMsg = jsonDecode(assistantMessages.last) as Map<String, dynamic>;
            final assistantIndex = sessions.indexWhere((s) => s['id'] == 'assistant');
            if (assistantIndex != -1) {
              sessions[assistantIndex]['lastMessage'] = lastMsg['text'] ?? 'Ask me about your health';
              sessions[assistantIndex]['time'] = lastMsg['time'] ?? '';
            }
          }
        }

        setState(() {
          _chats = sessions;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
      print('Error loading chats: $e');
    }
  }

  Future<void> _createConversation(String targetUserId) async {
    try {
      final token = await _getToken();
      if (token == null) return;
      final response = await http.post(
        Uri.parse('${_getBaseUrl()}/api/chat/conversations/user/$targetUserId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final convId = json['data']['id'];
        final name = json['data']['name'];
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailPage(
              chatId: convId,
              chatName: name,
            ),
          ),
        );
        _loadChats();
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Failed to create chat';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAddUserDialog() {
    final searchController = TextEditingController();
    List<Map<String, dynamic>> _searchResults = [];

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : Colors.black87;

        return StatefulBuilder(
          builder: (ctx, setState) {
            Future<void> searchUsers() async {
              final token = await _getToken();
              if (token == null) return;
              final response = await http.get(
                Uri.parse('${_getBaseUrl()}/api/chat/users/search?q=${Uri.encodeComponent(searchController.text)}'),
                headers: {'Authorization': 'Bearer $token'},
              );
              if (response.statusCode == 200) {
                final json = jsonDecode(response.body);
                setState(() {
                  _searchResults = List<Map<String, dynamic>>.from(json['data']);
                });
              }
            }

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              title: Text(
                'Start a chat',
                style: TextStyle(color: textColor),
              ),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Search by name or email',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                      onSubmitted: (_) => searchUsers(),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (_, idx) {
                          final user = _searchResults[idx];
                          return ListTile(
                            title: Text(
                              user['fullName'] ?? user['email'],
                              style: TextStyle(color: textColor),
                            ),
                            subtitle: Text(
                              user['role'] ?? '',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[700],
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              _createConversation(user['_id']);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatChatTime(dynamic rawTime) {
    if (rawTime == null) return '';

    final raw = rawTime.toString().trim();
    if (raw.isEmpty) return '';

    final parsed = DateTime.tryParse(raw);

    if (parsed == null) {
      return raw;
    }

    final date = parsed.toLocal();
    final now = DateTime.now();

    final isToday =
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;

    if (isToday) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (isYesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color background = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFE6F5E6);

    final Color cardColor = isDark
        ? const Color(0xFF1E1E1E)
        : Colors.white;

    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color secondaryTextColor = isDark ? Colors.grey[400]! : Colors.grey[700]!;
    final Color searchFillColor = isDark
        ? const Color(0xFF2A2A2A)
        : Colors.white;

    List<Map<String, dynamic>> filteredChats = _chats.where((chat) {
      if (_searchText.trim().isEmpty) return true;
      String query = _searchText.toLowerCase();
      String name = (chat['name'] ?? '').toString().toLowerCase();
      String lastMsg = (chat['lastMessage'] ?? '').toString().toLowerCase();
      return name.contains(query) || lastMsg.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: background,
      appBar: DefaultAppBar(),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            SizedBox(
              height: 50,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      'Chat',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: Icon(Icons.add, color: textColor),
                      onPressed: _showAddUserDialog,
                    ),
                  ),
                ],
              ),
            ),
            TextField(
              onChanged: (value) => setState(() => _searchText = value),
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                filled: true,
                fillColor: searchFillColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildBody(
                      filteredChats,
                      isDark: isDark,
                      cardColor: cardColor,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> filteredChats, {
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    if (filteredChats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No chats yet',
              style: TextStyle(color: secondaryTextColor),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _showAddUserDialog,
              child: const Text('Start new chat'),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: cardColor,
      child: ListView.separated(
        itemCount: filteredChats.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 0.5,
          color: isDark ? Colors.grey[800] : Colors.grey[300],
        ),
        itemBuilder: (context, index) {
          final chat = filteredChats[index];
          final name = (chat['name'] ?? 'Unknown Chat').toString();
          final lastMessage = (chat['lastMessage'] ?? 'No messages yet').toString();
          final time = _formatChatTime(chat['time']);

          final initials = (chat['initials'] != null &&
                  chat['initials'].toString().trim().isNotEmpty)
              ? chat['initials'].toString()
              : name.characters.take(2).join().toUpperCase();
          
          final unreadCount = (chat['unreadCount'] ?? 0) as int;
          final bool lastMessageFromMe = chat['lastMessageFromMe'] == true;

          return InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatDetailPage(
                    chatId: chat['id'],
                    chatName: name,
                  ),
                ),
              );
              _loadChats();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Stack(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: isDark
                            ? const Color(0xFF3A5A40)
                            : const Color(0xFFB6D9B6),
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              lastMessage.isNotEmpty ? lastMessage : 'No messages yet',
                              style: TextStyle(
                                fontSize: 13,
                                color: secondaryTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (time.isNotEmpty || unreadCount > 0 || lastMessageFromMe)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (time.isNotEmpty)
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: secondaryTextColor,
                                ),
                              ),
                            const SizedBox(height: 4),
                            if (unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            else if (lastMessageFromMe)
                              Icon(
                                Icons.done_all,
                                size: 16,
                                color: Colors.grey[500],
                              ),
                          ],
                        ),
                      
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}