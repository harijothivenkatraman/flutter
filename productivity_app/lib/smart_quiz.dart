import 'dart:async';
import 'package:flutter/material.dart';
import 'services/openai_service.dart';


class SmartQuiz extends StatefulWidget {
  const SmartQuiz({super.key});

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
  bool isAnswering = false;
  int timeRemaining = 30;
  Timer? timer;

  String selectedSubject = "Science";
  String selectedDifficulty = "Easy";

  List<String> subjects = ["Science", "Math", "History", "Geography", "Technology"];
  List<String> difficulties = ["Easy", "Medium", "Hard"];

  void startQuiz() async {
    setState(() {
      isLoading = true;
      isQuizStarted = true;
    });

    List<Map<String, dynamic>> fetchedQuestions =
    await apiService.fetchQuizQuestions(selectedSubject, selectedDifficulty);

    if (fetchedQuestions.isEmpty) {
      setState(() {
        isLoading = false;
        isQuizStarted = false;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Error"),
          content: Text("Failed to fetch questions. Please check your API key and try again."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      questions = fetchedQuestions;
      currentQuestionIndex = 0;
      score = 0;
      isLoading = false;
    });

    startTimer();
  }

  void checkAnswer(String selectedAnswer) {
    if (isAnswering) return;

    setState(() {
      isAnswering = true;
    });

    String correctAnswer = questions[currentQuestionIndex]["correctAnswer"];

    if (selectedAnswer.trim().toLowerCase() == correctAnswer.trim().toLowerCase()) {
      score++;
    }

    resetTimer();

    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        if (currentQuestionIndex < questions.length - 1) {
          currentQuestionIndex++;
          startTimer();
        } else {
          showFinalScore();
        }
        isAnswering = false;
      });
    });
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

  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (timeRemaining > 0) {
          timeRemaining--;
        } else {
          timer.cancel();
          checkAnswer("");
        }
      });
    });
  }

  void resetTimer() {
    timer?.cancel();
    timeRemaining = 30;
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Smart Quiz"),
        actions: [
          if (isQuizStarted)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  isQuizStarted = false;
                  questions = [];
                });
              },
            ),
        ],
      ),
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
          : questions.isEmpty
          ? Center(child: Text("No questions available."))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Question ${currentQuestionIndex + 1}/${questions.length}",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Time Remaining: $timeRemaining seconds",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              questions[currentQuestionIndex]["question"],
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Column(
              children: questions[currentQuestionIndex]["options"].map<Widget>((option) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    title: Text(option),
                    onTap: () => checkAnswer(option),
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