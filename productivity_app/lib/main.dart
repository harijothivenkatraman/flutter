import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:productivity_app/user_dasboard.dart';
import 'login_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'todolist.dart';
import 'alarms_list_page.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
// Import the new Alarms List Page


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();
  await Hive.openBox('todoBox');
  await Hive.initFlutter();
  await Hive.openBox('notesBox');
  await AndroidAlarmManager.initialize();
  var initializationSettingsAndroid = const AndroidInitializationSettings('@mipmap/ic_launcher');
  var initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  tz.initializeTimeZones();

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Self Craft',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthHandler(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/dashboard': (context) => UserDashboard(),
        '/alarms': (context) => AlarmsListPage(), // Add the new route
      },
    );
  }
}

class AuthHandler extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            return UserDashboard(); // User logged in
          }
          return LoginScreen(); // No user logged in
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}
