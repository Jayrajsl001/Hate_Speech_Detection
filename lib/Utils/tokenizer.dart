import 'dart:convert';
import 'package:flutter/services.dart';

class Tokenizer {
  final Map<String, int> wordIndex;
  final int maxLength = 16900; // Match model input shape

  Tokenizer(this.wordIndex);

  String cleanText(String text) {
    text = text.toLowerCase();
    text = text.replaceAll(RegExp(r'http\S+|www.\S+'), ''); // Remove URLs
    text = text.replaceAll(RegExp(r'[^a-z\s]'), ''); // Remove special chars
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim(); // Normalize spaces
    return text;
  }

  List<double> tokenize(String text) {
    text = cleanText(text);
    List<String> words = text.split(' ');

    List<double> inputVector = List.filled(maxLength, 0.0);

    for (int i = 0; i < words.length && i < maxLength; i++) {
      inputVector[i] =
          wordIndex[words[i]]?.toDouble() ?? 0.0; // Handle OOV words
    }

    return inputVector;
  }
}

Future<Tokenizer> loadTokenizer() async {
  try {
    String jsonString =
        await rootBundle.loadString('assets/tokenizer_vocab.json');

    // Extract word index from JSON
    Map<String, dynamic> rawJson = jsonDecode(jsonString);
    Map<String, dynamic> config = rawJson["config"];
    Map<String, dynamic> wordCounts = jsonDecode(config["word_counts"]);

    // Convert to Map<String, int>
    Map<String, int> wordIndex = {};
    int index = 1; // Start index from 1
    wordCounts.forEach((word, _) {
      wordIndex[word] = index++;
    });

    print("✅ Tokenizer loaded with ${wordIndex.length} words.");
    return Tokenizer(wordIndex);
  } catch (e) {
    throw Exception("❌ Error loading tokenizer: $e");
  }
}





// import 'dart:convert';
// import 'dart:math';
// import 'package:flutter/services.dart';

// class Tokenizer {
//   final Map<String, int> vocab;
//   final int maxLength = 16900; // Match model input shape

//   Tokenizer(this.vocab);

//   /// **Cleans text to match CountVectorizer preprocessing**
//   String cleanText(String text) {
//     text = text.toLowerCase();
//     text = text.replaceAll(RegExp(r'http\S+|www.\S+'), ''); // Remove URLs
//     text = text.replaceAll(RegExp(r'[^a-z\s]'), ''); // Remove punctuation & numbers
//     text = text.replaceAll(RegExp(r'\s+'), ' ').trim(); // Normalize spaces
//     return text;
//   }

//   /// **Tokenizes text using vocabulary**
//   List<double> tokenize(String text) {
//     text = cleanText(text);
//     List<String> words = text.split(' ');

//     List<double> inputVector = List.filled(maxLength, 0.0);

//     for (int i = 0; i < min(words.length, maxLength); i++) {
//       if (vocab.containsKey(words[i])) {
//         inputVector[i] = vocab[words[i]]!.toDouble(); // Use token ID
//       } else {
//         inputVector[i] = 0.0; // Unknown word
//       }
//     }

//     return inputVector;
//   }
// }

// /// **🔹 Load tokenizer from JSON**
// Future<Tokenizer> loadTokenizer() async {
//   String vocabJson = await rootBundle.loadString('assets/tokenizer_vocab.json');

//   // Parse JSON structure
//   Map<String, dynamic> rawVocab = jsonDecode(vocabJson);
//   if (!rawVocab.containsKey("config") || !rawVocab["config"].containsKey("word_counts")) {
//     throw Exception("Invalid tokenizer JSON format!");
//   }

//   // Extract and decode `word_counts` (which is stored as a string)
//   String wordCountsString = rawVocab["config"]["word_counts"];
//   Map<String, dynamic> wordCountsDecoded = jsonDecode(wordCountsString);

//   // Convert values to integers
//   Map<String, int> vocab = wordCountsDecoded.map((key, value) => MapEntry(key, value as int));

//   print("✅ Tokenizer loaded with ${vocab.length} words.");
//   return Tokenizer(vocab);
// }
