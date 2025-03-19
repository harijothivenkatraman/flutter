import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BMISuggestions extends StatefulWidget {
  @override
  _BMISuggestionsState createState() => _BMISuggestionsState();
}

class _BMISuggestionsState extends State<BMISuggestions> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  String _result = '';
  String _workoutSuggestion = '';
  bool _isLoading = false;

  // OpenRouter API Key
  final String apiKey = "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"; // Replace with your API key
  final String apiUrl = "https://openrouter.ai/api/v1/chat/completions";

  void _calculateBMI() async {
    double weight = double.tryParse(_weightController.text) ?? 0;
    double height = double.tryParse(_heightController.text) ?? 1;
    double bmi = weight / (height * height);

    String bmiCategory = bmi < 18.5
        ? 'Underweight'
        : bmi < 24.9
        ? 'Normal weight'
        : 'Overweight';

    setState(() {
      _result = bmiCategory;
      _isLoading = true;
    });

    // Fetch workout suggestions based on BMI category
    await _fetchWorkoutSuggestions(bmiCategory);
  }

  Future<void> _fetchWorkoutSuggestions(String bmiCategory) async {
    final Map<String, dynamic> requestData = {
      "model": "openai/gpt-3.5-turbo",
      "messages": [
        {"role": "system", "content": "You are a fitness coach."},
        {
          "role": "user",
          "content": "Suggest a weekly workout plan for someone who is $bmiCategory. Keep it concise and structured."
        }
      ]
    };

    try {
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
          String workoutPlan = responseData["choices"][0]["message"]["content"];
          setState(() {
            _workoutSuggestion = workoutPlan;
          });
        } else {
          throw Exception("Invalid response format: No choices found");
        }
      } else {
        throw Exception("Error: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      print("Failed to fetch workout suggestions: $e");
      setState(() {
        _workoutSuggestion = "Failed to fetch workout suggestions. Please try again.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('BMI Suggestions')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _weightController, decoration: InputDecoration(labelText: 'Weight (kg)')),
            TextField(controller: _heightController, decoration: InputDecoration(labelText: 'Height (m)')),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _calculateBMI,
              child: Text('Calculate BMI'),
            ),
            SizedBox(height: 10),
            Text(_result, style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            _isLoading
                ? CircularProgressIndicator()
                : Text(_workoutSuggestion, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}