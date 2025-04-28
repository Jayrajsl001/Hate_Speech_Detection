import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:hate_speech/DBhelper/mongodb.dart';
import 'package:hate_speech/Screens/HistoryDrawer.dart';
import 'package:hate_speech/Utils/tokenizer.dart';
import 'dart:math';

class Message {
  final String text;
  final bool isUser;

  Message({required this.text, required this.isUser});
}

class HateSpeechScreen extends StatefulWidget {
  final String userName;

  const HateSpeechScreen({super.key, required this.userName});

  @override
  _HateSpeechScreenState createState() => _HateSpeechScreenState();
}

class _HateSpeechScreenState extends State<HateSpeechScreen> {
  final TextEditingController _textController = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  List<List<double>> _modelOutput = [];
  final List<Message> _messages = [];
  Interpreter? _interpreter;
  Tokenizer? _tokenizer;
  final int inputSize = 16900; // Model requires fixed input size

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    loadModel();
  }

  Future<void> loadModel() async {
    try {
      _interpreter =
          await Interpreter.fromAsset('assets/hate_speech_model_final.tflite');
      print("✅ Model loaded successfully");
    } catch (e) {
      handleError("Error loading model: $e");
    }
  }

  Future<void> runModel(String inputText) async {
    try {
      _tokenizer ??= Tokenizer({
        "hate": 1,
        "speech": 2,
        "example": 3,
        // Add more words from training dataset
      });

      var processedInput = _tokenizer!.tokenize(inputText);
      List<double> inputTensor = List.filled(inputSize, 0.0); // Ensure fixed size

      for (int i = 0; i < min(processedInput.length, inputSize); i++) {
        inputTensor[i] = processedInput[i].toDouble();
      }

      var outputTensor = List.generate(1, (_) => List.filled(3, 0.0)); // Output shape [1,3]

      print("🔹 Input Tensor (First 10 values): ${inputTensor.sublist(0, 10)}");

      if (_interpreter != null) {
        _interpreter!.run([inputTensor], outputTensor);
        print("🔹 Model Output: $outputTensor");

        setState(() {
          _modelOutput = outputTensor;
        });
      } else {
        handleError("Model interpreter is null");
      }
    } catch (e) {
      handleError("Error processing input: $e");
    }
  }

  void _detectHateSpeech() {
    String inputText = _textController.text.trim();
    if (inputText.isEmpty) {
      handleError("Please enter or speak text before detecting.");
      return;
    }

    setState(() {
      _messages.add(Message(text: inputText, isUser: true));
    });

    _textController.clear();
    runModel(inputText);

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        if (_modelOutput.isEmpty || _modelOutput[0].isEmpty) {
          _messages.add(Message(text: "Try again for '$inputText' later.", isUser: false));
          return;
        }

        List<String> categories = [
          "No Hate Speech",
          "Offensive Speech",
          "Hate Speech"
        ];

        int predictedIndex = _modelOutput[0]
            .indexOf(_modelOutput[0].reduce((a, b) => a > b ? a : b));

        if (predictedIndex < 0 || predictedIndex >= categories.length) {
          _messages.add(Message(text: "Try again for '$inputText' later.", isUser: false));
        } else {
          String response = "Prediction: ${categories[predictedIndex]}";
          _messages.add(Message(text: response, isUser: false));

          mongodb.insertHistoryData(widget.userName, {
            'prompt': inputText,
            'response': response,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      });
    });
  }

  void _startListening() async {
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
      handleError("Error starting speech recognition: $e");
    }
  }

  void _stopListening() {
    try {
      setState(() => _isListening = false);
      _speech.stop();
    } catch (e) {
      handleError("Error stopping speech recognition: $e");
    }
  }

  void handleError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat with AI ✨"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      // drawer: HistoryDrawer(
      //   userName: widget.userName,
      //   onSelectHistory: (prompt, response) {
      //     setState(() {
      //       _messages.clear();
      //       _messages.add(Message(text: prompt, isUser: true));
      //       _messages.add(Message(text: response, isUser: false));
      //     });
      //   },
      //   onLogout: () {
      //     Navigator.of(context)
      //         .pushNamedAndRemoveUntil('/login', (route) => false);
      //     handleError("Logged out successfully.");
      //   },
      // ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessage(_messages[index]),
            ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: "Ask me anything...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                  color: _isListening ? Colors.red : Colors.blue,
                  onPressed: _isListening ? _stopListening : _startListening,
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _detectHateSpeech,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(Message message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12.0),
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: message.isUser
              ? Colors.blueAccent.withOpacity(0.8)
              : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.text,
          style:
              TextStyle(color: message.isUser ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}
