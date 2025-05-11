import 'message.dart';

class Room {
  final String id;
  final String name;
  final int numClients;
  final List<Message> messages;

  Room({
    required this.id,
    required this.name,
    required this.numClients,
    this.messages = const [],
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      name: json['name'],
      numClients: json['num_clients'],
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((m) => Message.fromJson(m))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'numClients': numClients,
    'messages': messages.map((m) => m.toJson()).toList(),
  };
}
