import 'package:flutter/material.dart';

/// A widget that provides a text input field and send button for chat messages.
class MessageInput extends StatefulWidget {
  /// Callback function when a message is sent
  final Function(String) onSendMessage;

  const MessageInput({super.key, required this.onSendMessage});

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final message = _textController.text.trim();
    if (message.isNotEmpty) {
      widget.onSendMessage(message);
      _textController.clear();
      _focusNode.requestFocus(); // Keep focus on the input field
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Text input field
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSubmit(),
            ),
          ),

          // Send button
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: IconButton(
              onPressed: _handleSubmit,
              icon: Icon(Icons.send, color: theme.colorScheme.primary),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primaryContainer.withOpacity(
                  0.4,
                ),
                shape: const CircleBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
