import 'package:flutter/material.dart';

class ChatDetailPage extends StatefulWidget {
  final String chatId;
  final String chatName;

  ChatDetailPage({
    super.key,
    required this.chatId,
    required this.chatName,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _controller = TextEditingController();

  // temp dummy messages – later you’ll load from backend by chatId
  final List<Map<String, dynamic>> _messages = [
    {
      'fromMe': false,
      'text':
          'Hi Alex! Based on your health data, I noticed your sleep quality was better than usual last night. Keep it up!',
      'time': '14:30',
    },
    {
      'fromMe': true,
      'text': 'My heart rate was high this morning.',
      'time': '14:55',
    },
    {
      'fromMe': false,
      'text':
          'I noticed that. Your resting heart rate was 85 BPM this morning vs. your usual 72 BPM. This could be related to:\n\n☑ Insufficient sleep last night\n☑ High caffeine intake\n☑ Morning stress\n\n[View Detailed Analysis]   [Log Symptom]',
      'time': '14:55',
    },
  ];

  @override
  Widget build(BuildContext context) {
    Color background = Color(0xFFE6F5E6);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🤖 ', style: TextStyle(fontSize: 18)),
            Text(
              widget.chatName,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.black87),
            onPressed: () {
              // e.g. options / actions
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // messages
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: _messages.length + 1, // +1 for date header
              itemBuilder: (context, index) {
                if (index == 0) {
                  // date / time header like "Wednesday 14:30"
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Text(
                        'Wednesday 14:30',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  );
                }

                final msg = _messages[index - 1];
                bool fromMe = msg['fromMe'] == true;
                return _buildMessageBubble(
                  text: msg['text'] ?? '',
                  time: msg['time'] ?? '',
                  fromMe: fromMe,
                );
              },
            ),
          ),

          // input bar
          Container(
            padding: EdgeInsets.fromLTRB(12, 6, 12, 12),
            color: background,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message.....',
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
                    ),
                  ),
                ),
                SizedBox(width: 8),
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
    Alignment alignment =
        fromMe ? Alignment.centerRight : Alignment.centerLeft;
    Color bubbleColor = fromMe ? Colors.white : Colors.white;
    EdgeInsets margin = fromMe
        ? EdgeInsets.fromLTRB(80, 4, 0, 4)
        : EdgeInsets.fromLTRB(0, 4, 80, 4);

    return Align(
      alignment: alignment,
      child: Container(
        margin: margin,
        padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
              fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 4),
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
    );
  }

  void _handleSend() {
    String text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'fromMe': true,
        'text': text,
        'time': '15:00', // temp; later from backend or DateTime.now()
      });
    });

    _controller.clear();
  }
}
