import 'package:auth2_flutter/features/chat/presentation/pages/individual_chat_page.dart';
import 'package:auth2_flutter/features/data/backend_auth_respository.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/appbar.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final BackendAuthRepository _authRepo = BackendAuthRepository();

  List<Map<String, dynamic>> _chats = [];
  bool _loading = true;
  String? _error;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final chats = await _authRepo.getChats();
      setState(() {
        _chats = chats;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color background = Color(0xFFE6F5E6);

    // filter by search
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
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            SizedBox(
  height: 50,
  child: Stack(
    alignment: Alignment.center,
    children: [
      // Centered Title
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

      // Right-side button
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


            // search bar
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search',
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

            // content area
            Expanded(child: _buildBody(filteredChats)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> filteredChats) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Failed to load chats',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
            SizedBox(height: 8),
            TextButton(onPressed: _loadChats, child: Text('Retry')),
          ],
        ),
      );
    }

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
        separatorBuilder: (context, index) {
          return Divider(height: 1, thickness: 0.5, color: Colors.grey[300]);
        },
        itemBuilder: (context, index) {
          final chat = filteredChats[index];

          String name = (chat['name'] ?? '').toString();
          String lastMessage = (chat['lastMessage'] ?? '').toString();
          String time = (chat['time'] ?? '').toString();

          // either backend sends initials, or we generate from name
          String initials = (chat['initials'] ?? _getInitialsFromName(name))
              .toString();

          return InkWell(
            onTap: () {
              String chatId = (chat['id'] ?? '').toString();
              String chatName = (chat['name'] ?? '').toString();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ChatDetailPage(chatId: chatId, chatName: chatName),
                ),
              );
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
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
                  SizedBox(width: 8),
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

  String _getInitialsFromName(String name) {
    if (name.trim().isEmpty) return '';
    List<String> parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
