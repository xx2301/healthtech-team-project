import 'package:auth2_flutter/features/chat/presentation/pages/chat_detail_page.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/appbar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ChatPage extends StatefulWidget {
  ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> _chats = [];
  String _searchText = '';
  String? _lastMessage;
  String? _lastTime;

  @override
  void initState() {
    super.initState();
    _loadLastMessage();
  }

  Future<void> _loadLastMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('chat_assistant');
    if (saved != null && saved.isNotEmpty) {
      final lastMsg = jsonDecode(saved.last) as Map<String, dynamic>;
      setState(() {
        _lastMessage = lastMsg['text'];
        _lastTime = lastMsg['time'];
      });
    } else {
      // 没有消息时，使用默认占位
      setState(() {
        _lastMessage = 'Ask me about your health';
        _lastTime = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color background = Color(0xFFE6F5E6);

    // 构建动态的聊天列表（目前只有一个助手，但可扩展）
    final List<Map<String, dynamic>> chats = [
      {
        'id': 'assistant',
        'name': 'Health Assistant',
        'lastMessage': _lastMessage ?? 'Ask me about your health',
        'time': _lastTime ?? '',
        'initials': 'HA',
      }
    ];

    List<Map<String, dynamic>> filteredChats = chats.where((chat) {
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
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.black87),
                      onPressed: () {
                        // TODO: start new chat
                      },
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
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              ),
            ),
            SizedBox(height: 16),
            Expanded(child: _buildBody(filteredChats)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> filteredChats) {
    if (filteredChats.isEmpty) {
      return Center(
        child: Text('No chats yet', style: TextStyle(color: Colors.grey[600])),
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
          final name = chat['name'];
          final lastMessage = chat['lastMessage'];
          final time = chat['time'];
          final initials = chat['initials'];

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatDetailPage(
                    chatId: chat['id'],
                    chatName: name,
                  ),
                ),
              ).then((_) => _loadLastMessage()); // 返回时刷新预览
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0xFFB6D9B6),
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          lastMessage,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
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
                        SizedBox(height: 4),
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