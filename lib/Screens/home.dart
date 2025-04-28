import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:hate_speech/DBhelper/mongodb.dart';
import 'package:hate_speech/Screens/HistoryDrawer.dart';
import 'package:hate_speech/Utils/themeProvider.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:convert';
import 'package:hate_speech/Screens/Login.dart';
import 'package:http/http.dart' as http;

class Message1 {
  final String text;
  final bool isUser;
  final String category;

  Message1({required this.text, required this.isUser, required this.category});

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'category': category,
    };
  }
}

class Home extends StatefulWidget {
  // final String userName;

  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _textController = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  List<Message1> _messages = [];
  String _chatName = "New Chat";
  String? _chatId;
  List<Map<String, dynamic>> _chatSession = [];
  int _freeChatsRemaining = 3;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _showLoginPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sign In Required"),
        content: const Text(
            "You have used 3 free chats. Please log in to continue."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
            child: const Text("Log In"),
          ),
        ],
      ),
    );
  }

  String generateChatId1() {
    final Random random = Random();
    return DateTime.now().millisecondsSinceEpoch.toString() +
        "-" +
        random.nextInt(10000).toString();
  }

  String _extractChatName1(String text) {
    List<String> words = text.split(" ");
    if (words.length >= 3) {
      return words.sublist(0, 3).join(" ");
    } else {
      return words.join(" ");
    }
  }

  static const String API_KEY = "your_api_key";
  static const String API_URL =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-thinking-exp:generateContent?key=$API_KEY";

  void _detectHateSpeech1() async {
    if (_freeChatsRemaining == 0) {
      _showLoginPopup();
      return;
    }
    String inputText = _textController.text.trim();
    if (inputText.isEmpty) {
      handleError1("Please enter or speak text before detecting.");
      return;
    }

    setState(() {
      Message1 userMessage =
          Message1(text: inputText, isUser: true, category: "User Input");
      _messages.add(userMessage);
    });

    _textController.clear();

    try {
      print("📝 Checking for existing chat ID: $_chatId");

      if (_chatId?.isEmpty ?? true) {
        _chatId = generateChatId1();
        _chatName = _extractChatName1(inputText);
        print(
            "⚠️ No existing chat. Creating new chat ID: $_chatId with name: $_chatName");
      }

      final response = await http.post(
        Uri.parse(API_URL),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "API_KEY",
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text":
                      "Classify the following text as one of the three categories: 'No Hate Speech', 'Offensive Language', or 'Hate Speech'. Just answer in one word, no explanation.\n\nText: $inputText"
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        var responseBody = jsonDecode(response.body);
        String responseText =
            responseBody["candidates"][0]["content"]["parts"][0]["text"].trim();

        setState(() {
          Message1 botResponse = Message1(
              text: responseText, isUser: false, category: responseText);
          _freeChatsRemaining--;
          _messages.add(botResponse);
        });
      } else {
        print("❌ Error: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      print("❌ Exception: $e");
    }
  }

  void _startListening1() async {
    try {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _textController.text = result.recognizedWords;
            });
          },
        );
      }
    } catch (e) {
      handleError1("Error starting speech recognition: $e");
    }
  }

  void _stopListening1() {
    try {
      setState(() => _isListening = false);
      _speech.stop();
    } catch (e) {
      handleError1("Error stopping speech recognition: $e");
    }
  }

  void handleError1(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hate Speech Detector"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text(
              "Login",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessage1(_messages[index]),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: isDarkMode ? Colors.black : Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: "Type something...",
                      hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey : Colors.black),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _detectHateSpeech1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage1(Message1 message) {
    bool isUserMessage = message.isUser;

    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUserMessage
              ? Color.fromARGB(255, 88, 151, 190)
              : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isUserMessage ? const Radius.circular(12) : Radius.zero,
            bottomRight:
                isUserMessage ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUserMessage ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
