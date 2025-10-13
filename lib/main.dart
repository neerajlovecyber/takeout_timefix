import 'package:flutter/material.dart';
import 'screens/home_page.dart';

void main() {
  runApp(const TakeoutTimeFixApp());
}

class TakeoutTimeFixApp extends StatelessWidget {
  const TakeoutTimeFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Takeout TimeFix',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

