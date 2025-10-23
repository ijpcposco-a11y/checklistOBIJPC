import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'checklist_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Checklist OB IJPC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FutureBuilder<bool>(
        future: checkLoginStatus(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return snapshot.data! ? const ChecklistPage() : const LoginPage();
        },
      ),
    );
  }
}
