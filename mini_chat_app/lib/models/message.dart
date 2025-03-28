// MessageType enum mirrors the MessageType constants defined in the Go backend
// Corresponds to: TextMessage, SystemMessage, RoomUpdateMessage, and now ImageMessage
enum MessageType { text, system, roomUpdate, image }

// Message class mirrors the Message struct in the Go backend
// Used for converting messages between Flutter client and backend
class Message {
  // Fields match the JSON tags defined in the Go Message struct
  final MessageType type; // Type of message (text, system, room_update, image)
  final String content; // Message content
  final String sender; // Message sender
  final String room; // Room ID where message was sent
  final int timestamp; // Unix timestamp when message was sent
  final List<String>? imagePaths; // Optional paths to images from image_picker

  Message({
    required this.type,
    required this.content,
    required this.sender,
    required this.room,
    required this.timestamp,
    this.imagePaths,
  });

  // Creates a frontend Message from JSON received from Go backend
  // Handles converting string message type to enum
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
      ),
      content: json['content'],
      sender: json['sender'],
      room: json['room'],
      timestamp: json['timestamp'],
      imagePaths:
          json['image_paths'] != null
              ? List<String>.from(json['image_paths'])
              : null,
    );
  }

  // Converts Message to JSON format expected by Go backend
  // Handles converting enum message type to string
  Map<String, dynamic> toJson() => {
    'type': type.toString().split('.').last,
    'content': content,
    'sender': sender,
    'room': room,
    'timestamp': timestamp,
    'image_paths': imagePaths,
  };
}
