import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:productivity_app/user_dasboard.dart';
import 'login_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'todolist.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();
  await Hive.openBox('todoBox');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Productivity App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthHandler(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/dashboard': (context) => UserDashboard(),
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
