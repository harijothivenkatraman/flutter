import 'package:flutter/material.dart';
import 'package:productivity_app/services/openai_service.dart';

class SmartQuiz extends StatefulWidget {
  @override
  _SmartQuizState createState() => _SmartQuizState();
}

class _SmartQuizState extends State<SmartQuiz> {
  OpenAIService apiService = OpenAIService();
  List<Map<String, dynamic>> questions = [];
  int currentQuestionIndex = 0;
  int score = 0;
  bool isLoading = false;
  bool isQuizStarted = false;

  // Default selections
  String selectedSubject = "Science";
  String selectedDifficulty = "Easy";

  List<String> subjects = [
    "Science",
    "Math",
    "History",
    "Geography",
    "Technology"
  ];
  List<String> difficulties = ["Easy", "Medium", "Hard"];

  void startQuiz() async {
    setState(() {
      isLoading = true;
      isQuizStarted = true;
    });

    List<Map<String, dynamic>> fetchedQuestions = await apiService
        .fetchQuizQuestions(selectedSubject, selectedDifficulty);

    setState(() {
      questions = fetchedQuestions;
      currentQuestionIndex = 0;
      score = 0;
      isLoading = false;
    });
  }

  void checkAnswer(String selectedAnswer) {
    String correctAnswer = questions[currentQuestionIndex]["correctAnswer"];

    if (selectedAnswer.trim().toLowerCase() ==
        correctAnswer.trim().toLowerCase()) {
      score++;
    }

    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    } else {
      showFinalScore();
    }
  }

  void showFinalScore() {
    String resultText = "Your final score is $score/${questions.length}\n\n";

    for (var i = 0; i < questions.length; i++) {
      resultText += "Q${i + 1}: ${questions[i]["question"]}\n";
      resultText += "Correct Answer: ${questions[i]["correctAnswer"]}\n\n";
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Quiz Completed!"),
        content: SingleChildScrollView(
          child: Text(resultText),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                isQuizStarted = false;
                questions = [];
              });
            },
            child: Text("Restart"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Smart Quiz")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : !isQuizStarted
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButton<String>(
              value: selectedSubject,
              items: subjects.map((String subject) {
                return DropdownMenuItem<String>(
                  value: subject,
                  child: Text(subject),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedSubject = value!;
                });
              },
            ),
            DropdownButton<String>(
              value: selectedDifficulty,
              items: difficulties.map((String difficulty) {
                return DropdownMenuItem<String>(
                  value: difficulty,
                  child: Text(difficulty),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDifficulty = value!;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: startQuiz,
              child: Text("Start Quiz"),
            ),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Question ${currentQuestionIndex + 1}/${questions.length}",
              style:
              TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              questions[currentQuestionIndex]["question"],
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Column(
              children:
              questions[currentQuestionIndex]["options"].map<Widget>((option) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ElevatedButton(
                    onPressed: () => checkAnswer(option),
                    child: Text(option),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}