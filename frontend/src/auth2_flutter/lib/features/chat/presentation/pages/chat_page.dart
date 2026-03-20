import 'package:auth2_flutter/features/chat/presentation/pages/chat_detail_page.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/appbar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> _chats = [];
  bool _loading = true;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
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

      print('chat response: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        List<Map<String, dynamic>> sessions = List<Map<String, dynamic>>.from(json['data']);

        final prefs = await SharedPreferences.getInstance();
        final assistantMessages = prefs.getStringList('chat_assistant');
        if (assistantMessages != null && assistantMessages.isNotEmpty) {
          final lastMsg = jsonDecode(assistantMessages.last) as Map<String, dynamic>;
          final assistantIndex = sessions.indexWhere((s) => s['id'] == 'assistant');
          if (assistantIndex != -1) {
            sessions[assistantIndex]['lastMessage'] = lastMsg['text'] ?? 'Ask me about your health';
            sessions[assistantIndex]['time'] = lastMsg['time'] ?? '';
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
      builder: (ctx) => StatefulBuilder(
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
            title: const Text('Start a chat'),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(hintText: 'Search by name or email'),
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
                          title: Text(user['fullName'] ?? user['email']),
                          subtitle: Text(user['role'] ?? ''),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color background = const Color(0xFFE6F5E6);

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
                  const Center(
                    child: Text(
                      'Chat',
                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.black87),
                      onPressed: _showAddUserDialog,
                    ),
                  ),
                ],
              ),
            ),
            TextField(
              onChanged: (value) => setState(() => _searchText = value),
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildBody(filteredChats),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> filteredChats) {
    if (filteredChats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('No chats yet', style: TextStyle(color: Colors.grey[600])),
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
      color: Colors.white,
      child: ListView.separated(
        itemCount: filteredChats.length,
        separatorBuilder: (context, index) => Divider(height: 1, thickness: 0.5, color: Colors.grey[300]),
        itemBuilder: (context, index) {
          final chat = filteredChats[index];
          final name = (chat['name'] ?? 'Unknown Chat').toString();
          final lastMessage = (chat['lastMessage'] ?? 'No messages yet').toString();
          final time = (chat['time'] ?? '').toString();

          final initials = (chat['initials'] != null &&
                  chat['initials'].toString().trim().isNotEmpty)
              ? chat['initials'].toString()
              : name.characters.take(2).join().toUpperCase();

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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFB6D9B6),
                    child: Text(
                      initials,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lastMessage.isNotEmpty ? lastMessage : 'No messages yet',
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (time.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          time,
                          style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 4),
                        Icon(Icons.done_all, size: 16, color: Colors.grey[500]),
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