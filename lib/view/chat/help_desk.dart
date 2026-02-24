import 'package:flutter/material.dart';
import 'package:pcos_app/widgets/app_scaffold.dart';

class HelpDesk extends StatefulWidget {
  const HelpDesk({super.key});

  @override
  _HelpDeskState createState() => _HelpDeskState();
}

class _HelpDeskState extends State<HelpDesk> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      "sender": "bot",
      "text": "I'm an AI-powered Assistant. How can I help you today?"
    },
    {
      "sender": "bot",
      "text":
          "So that I can assist you as best as possible, please:\n⭐ Send one message at a time\n⭐ Write about one topic in one message"
    }
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({"sender": "user", "text": text});
      // Simple bot response logic
      String response =
          "Hello! How can I assist you today? If you have any questions or need help, feel free to ask.";
      if (text.toLowerCase().contains("hello")) {
        // Keep the generic response for "hello"
      } else if (text.toLowerCase().contains("theme")) {
        response =
            "You can change the theme in the General Settings page, which you can find in the Profile Settings.";
      } else if (text.toLowerCase().contains("cycle")) {
        response =
            "You can log your cycle from the homepage calendar or the dedicated Cycle Logging page.";
      }
      _messages.add({"sender": "bot", "text": response});
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      currentIndex: 2,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['sender'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color:
                          isUser ? theme.colorScheme.primary : theme.cardColor,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Text(
                      message['text']!,
                      style: TextStyle(
                        color: isUser
                            ? theme.colorScheme.onPrimary
                            : theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildMessageComposer(theme),
        ],
      ),
    );
  }

  Widget _buildMessageComposer(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file, color: theme.iconTheme.color),
            onPressed: () {
              // TODO: Implement file attachment
            },
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type a message',
                hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
                filled: true,
                fillColor: theme.scaffoldBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: theme.colorScheme.primary),
            onPressed: () => _sendMessage(_controller.text),
          ),
        ],
      ),
    );
  }
}
