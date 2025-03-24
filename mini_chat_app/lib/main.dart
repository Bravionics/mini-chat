import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pages/room_list_page.dart';
import 'providers/chat_provider.dart';
import 'services/chat_service.dart';
import 'services/openai_service.dart';

// Don't expose key in production.
const String openAiApiKey = '';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Create the OpenAI service with the API key
    final openAIService =
        openAiApiKey.isNotEmpty ? OpenAIService(apiKey: openAiApiKey) : null;

    return ChangeNotifierProvider(
      create:
          (context) =>
              ChatProvider(ChatService(), openAIService: openAIService),
      child: MaterialApp(
        title: 'Mini Chat App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          typography: Typography.material2021(),
        ),
        home: const RoomListPage(),
      ),
    );
  }
}
