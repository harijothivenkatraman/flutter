import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:productivity_app/user_dasboard.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'todolist.dart';
import 'alarms_list_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_dotenv/flutter_dotenv.dart';




final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase based on platform
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCLYf-smrmEpFjtuKWqcWLWNahpwU2-7YY",
        authDomain: "productivity-app-c9c23.firebaseapp.com",
        projectId: "productivity-app-c9c23",
        storageBucket: "productivity-app-c9c23.appspot.com",
        messagingSenderId: "825770877454",
        appId: "1:825770877454:web:0869657145bc51d7f0925f",
        measurementId: "G-N5ZEXN1DW1",
      ),
    );
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  await dotenv.load();

  await Hive.initFlutter();
  await Hive.openBox('todoBox');
  await Hive.openBox('notesBox');

  tz.initializeTimeZones();

  // ✅ Only initialize alarms and notifications on Android
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await AndroidAlarmManager.initialize();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initSettings = InitializationSettings(android: androidSettings);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

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
        '/alarms': (context) => AlarmsListPage(),
        '/signup': (context) => SignUpScreen(),// Add the new route
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
