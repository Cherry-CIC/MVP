import 'package:flutter/material.dart';

class ChatMessage {
  final String message;
  final bool isUser;

  ChatMessage({required this.message, required this.isUser});
}

class ChatPage extends StatefulWidget {
  final bool showAppBar;

  const ChatPage({this.showAppBar = true});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(message: "Hi! Need help finding something?", isUser: false),
    ChatMessage(message: "Yes, I’m looking for wireless headphones.", isUser: true),
    ChatMessage(message: "Sure! We have great options. Any specific brand?", isUser: false),
  ];

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add(ChatMessage(message: text, isUser: true));
        _controller.clear();

        Future.delayed(Duration(milliseconds: 500), () {
          setState(() {
            _messages.add(ChatMessage(
              message: "Thanks for your message! We'll get back to you shortly.",
              isUser: false,
            ));
          });
        });
      });
    }
  }

  Widget _buildMessage(ChatMessage chat) {
    return Align(
      alignment: chat.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: chat.isUser ? Colors.blue[200] : Colors.pink[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(chat.message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(title: Text("Chat Support")) : null,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            if (!widget.showAppBar)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  "Quick Chat",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10),
                itemCount: _messages.length,
                itemBuilder: (context, index) => _buildMessage(_messages[index]),
              ),
            ),
            Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: _sendMessage,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
