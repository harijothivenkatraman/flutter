import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class BMISuggestions extends StatefulWidget {
  @override
  _BMISuggestionsState createState() => _BMISuggestionsState();
}

class _BMISuggestionsState extends State<BMISuggestions> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  String _result = '';

  void _calculateBMI() {
    double weight = double.tryParse(_weightController.text) ?? 0;
    double height = double.tryParse(_heightController.text) ?? 1;
    double bmi = weight / (height * height);

    setState(() {
      _result = bmi < 18.5
          ? 'Underweight - Eat more nutritious food.'
          : bmi < 24.9
          ? 'Normal weight - Keep up the good work!'
          : 'Overweight - Consider a balanced diet and exercise.';
    });
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
            ElevatedButton(onPressed: _calculateBMI, child: Text('Calculate BMI')),
            SizedBox(height: 10),
            Text(_result, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
