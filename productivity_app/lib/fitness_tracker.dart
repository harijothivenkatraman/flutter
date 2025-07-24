import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:permission_handler/permission_handler.dart';

class FitnessTracker extends StatefulWidget {
  @override
  _FitnessTrackerState createState() => _FitnessTrackerState();
}

class _FitnessTrackerState extends State<FitnessTracker> {
  int _stepCount = 0;
  late Stream<StepCount> _stepCountStream;
  final int _dailyGoal = 10000;

  @override
  void initState() {
    super.initState();
    _requestPermission();
    _initStepCounter();
  }

  void _requestPermission() async {
    var status = await Permission.activityRecognition.status;
    if (!status.isGranted) {
      await Permission.activityRecognition.request();
    }
  }

  void _initStepCounter() {
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen((StepCount event) {
      setState(() {
        _stepCount = event.steps;
      });
    }, onError: (error) {
      print("Step Count Error: $error");
    });
  }

  double get _progress => (_stepCount / _dailyGoal).clamp(0.0, 1.0);

  int get _caloriesBurned => (_stepCount * 0.04).toInt(); // Rough estimate
  double get _distanceKm => (_stepCount * 0.0008); // Average step = 0.8m

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Fitness Tracker")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircularPercentIndicator(
              radius: 150.0,
              lineWidth: 15.0,
              percent: _progress,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("$_stepCount", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                  Text("Steps", style: TextStyle(fontSize: 18)),
                ],
              ),
              progressColor: Colors.green,
              backgroundColor: Colors.grey.shade300,
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
            ),
            SizedBox(height: 40),
            _buildStatCard("Distance", "${_distanceKm.toStringAsFixed(2)} km", Icons.directions_walk),
            _buildStatCard("Calories", "$_caloriesBurned kcal", Icons.local_fire_department),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(icon, size: 30, color: Colors.blueAccent),
        title: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        trailing: Text(value, style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
