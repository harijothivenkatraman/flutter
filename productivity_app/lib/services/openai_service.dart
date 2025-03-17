import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  final String apiKey = "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"; // Replace with actual API key
  final String apiUrl = "https://openrouter.ai/api/v1/chat/completions";

  Future<List<Map<String, dynamic>>> fetchQuizQuestions(String subject, String difficulty) async {
    final Map<String, dynamic> requestData = {
      "model": "openai/gpt-3.5-turbo",
      "messages": [
        {"role": "system", "content": "You are a quiz generator."},
        {"role": "user", "content": "Generate 10 multiple-choice questions on $subject with $difficulty difficulty. Each question should have 4 options. At the end of each question, include 'Correct Answer: <option>'. Keep the format clean."}
      ]
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json"
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String generatedText = responseData["choices"][0]["message"]["content"];
        return parseQuestions(generatedText);
      } else {
        throw Exception("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Failed to fetch questions: $e");
      return [];
    }
  }

  List<Map<String, dynamic>> parseQuestions(String text) {
    List<String> lines = text.split("\n");
    List<Map<String, dynamic>> parsedQuestions = [];

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains("?")) {  // Detecting question
        String question = lines[i];
        List<String> options = [];

        // Extract the next 4 lines as options
        for (int j = 1; j <= 4; j++) {
          if (i + j < lines.length) {
            options.add(lines[i + j].trim());
          }
        }

        // Extract correct answer
        String correctAnswer = "";
        for (int j = i + 5; j < lines.length; j++) {
          if (lines[j].startsWith("Correct Answer:")) {
            correctAnswer = lines[j].replaceAll("Correct Answer:", "").trim();
            break;
          }
        }

        parsedQuestions.add({
          "question": question,
          "options": options,
          "correctAnswer": correctAnswer,
        });
      }
    }

    return parsedQuestions;
  }
}
