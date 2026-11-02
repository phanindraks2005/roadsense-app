import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const RoadSenseApp());
}

class RoadSenseApp extends StatelessWidget {
  const RoadSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoadSense',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomeScreen(),
    );
  }
}
