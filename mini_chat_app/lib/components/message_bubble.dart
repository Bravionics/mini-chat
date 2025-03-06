import 'package:flutter/material.dart';
import '../models/message.dart';

/// A widget that displays a chat message in a rectangular container
/// with a slight border to separate it from the background.
class MessageBubble extends StatelessWidget {
  /// The message to display
  final Message message;

  /// Whether this message was sent by the current user
  final bool isCurrentUser;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // System messages have a different style
    if (message.type == MessageType.system) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            message.content,
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          decoration: BoxDecoration(
            color:
                isCurrentUser
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : Colors.white,
            border: Border.all(
              color:
                  isCurrentUser
                      ? theme.colorScheme.primary.withOpacity(0.3)
                      : Colors.grey.shade300,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sender name
              if (!isCurrentUser)
                Text(
                  message.sender,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),

              // Message content
              Text(message.content, style: textTheme.bodyMedium),

              // Timestamp
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    _formatTimestamp(message.timestamp),
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formats a Unix timestamp into a readable time string
  String _formatTimestamp(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    // Format: HH:MM
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    // If message is from today, just show time
    if (messageDate == today) {
      return time;
    }

    // If message is from yesterday, show "Yesterday, HH:MM"
    final yesterday = today.subtract(const Duration(days: 1));
    if (messageDate == yesterday) {
      return 'Yesterday, $time';
    }

    // Otherwise show MM/DD/YYYY, HH:MM
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}, $time';
  }
}
