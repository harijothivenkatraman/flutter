import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'todolist.dart';
import 'reminder.dart';
import 'fitness_tracker.dart';
import 'bmi_suggestions.dart';
import 'smart_quiz.dart';

class UserDashboard extends StatefulWidget {
  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> logout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login'); // Redirect to login page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          DashboardItem(
            icon: Icons.list,
            title: 'To-Do List',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ToDoList())),
          ),
          DashboardItem(
            icon: Icons.alarm,
            title: 'Reminder Alarms',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Reminder())),
          ),
          DashboardItem(
            icon: Icons.fitness_center,
            title: 'Fitness Tracker',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FitnessTracker())),
          ),
          DashboardItem(
            icon: Icons.calculate,
            title: 'BMI Suggestions',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BMISuggestions())),
          ),
          DashboardItem(
            icon: Icons.quiz,
            title: 'Smart Quiz',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SmartQuiz())),
          ),
        ],
      ),
    );
  }
}

class DashboardItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const DashboardItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, size: 30, color: Colors.blue),
        title: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        trailing: Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
