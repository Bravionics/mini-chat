import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/message.dart';
import '../models/room.dart';

class ChatService {
  final String _wsURL = 'wss://mini-chat-103702261730.us-west2.run.app/ws';
  final String _httpURL = 'https://mini-chat-103702261730.us-west2.run.app';
  late final WebSocketChannel _channel;

  // Stream controller for messages
  Stream<Message> get messages => _channel.stream.map((data) {
    final jsonData = jsonDecode(data);
    return Message.fromJson(jsonData);
  });

  // Initialize WebSocket connection
  Future<void> connect() async {
    _channel = WebSocketChannel.connect(Uri.parse(_wsURL));
  }

  // Send message
  void sendMessage(Message msg) {
    _channel.sink.add(jsonEncode(msg.toJson()));
  }

  // Get rooms
  Future<List<Room>> getRooms() async {
    final response = await http.get(Uri.parse('$_httpURL/rooms'));
    if (response.statusCode == 200) {
      final List<dynamic> roomsJson = jsonDecode(response.body);
      return roomsJson.map((json) => Room.fromJson(json)).toList();
    }
    throw Exception('Failed to get rooms');
  }

  // Create room
  Future<void> createRoom(String name) async {
    final response = await http.post(
      Uri.parse('$_httpURL/rooms/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to create room');
    }
  }

  // Join room
  void joinRoom(String roomID) {
    final msg = Message(
      type: MessageType.system,
      content: 'join',
      sender: 'system',
      room: roomID,
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    sendMessage(msg);
  }

  void dispose() {
    _channel.sink.close();
  }
}
