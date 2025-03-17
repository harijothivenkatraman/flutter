import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';

class FitnessTracker extends StatefulWidget {
  @override
  _FitnessTrackerState createState() => _FitnessTrackerState();
}

class _FitnessTrackerState extends State<FitnessTracker> {
  int _stepCount = 0;
  late Stream<StepCount> _stepCountStream;

  @override
  void initState() {
    super.initState();
    _initStepCounter();
  }

  void _initStepCounter() {
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen((StepCount event) {
      setState(() {
        _stepCount = event.steps;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Fitness Tracker")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("🚶 Steps Taken:", style: TextStyle(fontSize: 22)),
            Text("$_stepCount", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
