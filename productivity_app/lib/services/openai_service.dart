import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  final String apiKey = "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"; // Replace with actual API key
  final String apiUrl = "https://openrouter.ai/api/v1/chat/completions";

  Future<List<Map<String, dynamic>>> fetchQuizQuestions(String subject, String difficulty) async {
    if (apiKey.isEmpty || apiUrl.isEmpty) {
      throw Exception("API key or URL is missing");
    }

    final Map<String, dynamic> requestData = {
      "model": "openai/gpt-3.5-turbo",
      "messages": [
        {"role": "system", "content": "You are a quiz generator."},
        {"role": "user", "content": "Generate 10 multiple-choice questions on $subject with $difficulty difficulty. Each question should have 4 options. At the end of each question, include 'Correct Answer: <option>'. Keep the format clean."}
      ]
    };

    try {
      print("API Key: $apiKey");
      print("API URL: $apiUrl");
      print("Request Headers: ${{
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      }}");
      print("Request Body: ${jsonEncode(requestData)}");

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData.containsKey("choices") && responseData["choices"].isNotEmpty) {
          String generatedText = responseData["choices"][0]["message"]["content"];
          return parseQuestions(generatedText);
        } else {
          throw Exception("Invalid response format: No choices found");
        }
      } else if (response.statusCode == 401) {
        throw Exception("Unauthorized: Check your API key");
      } else {
        throw Exception("Error: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      print("Failed to fetch questions: $e");
      return [];
    }
  }

  List<Map<String, dynamic>> parseQuestions(String text) {
    List<String> lines = text.split("\n");
    List<Map<String, dynamic>> parsedQuestions = [];
    int i = 0;

    while (i < lines.length) {
      if (lines[i].contains("?")) { // Detecting question
        String question = lines[i].trim();
        List<String> options = [];
        String correctAnswer = "";

        // Extract the next 4 lines as options
        for (int j = 1; j <= 4; j++) {
          if (i + j < lines.length && lines[i + j].trim().isNotEmpty) {
            options.add(lines[i + j].trim());
          } else {
            options.add("Option $j"); // Fallback if options are missing
          }
        }

        // Extract correct answer
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

        i += 6; // Move to the next question
      } else {
        i++; // Skip non-question lines
      }
    }

    return parsedQuestions;
  }
}