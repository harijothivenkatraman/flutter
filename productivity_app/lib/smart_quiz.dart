import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class SmartQuiz extends StatefulWidget {
  @override
  _SmartQuizState createState() => _SmartQuizState();
}

class _SmartQuizState extends State<SmartQuiz> {
  Interpreter? _interpreter;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/quiz_model.tflite');
  }

  void _predictAnswer() {
    // Placeholder for ML-based quiz logic
    print("Predicting answer...");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Smart Quiz')),
      body: Center(
        child: ElevatedButton(
          onPressed: _predictAnswer,
          child: Text('Start Quiz'),
        ),
      ),
    );
  }
}
