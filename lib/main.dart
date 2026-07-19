import 'package:flutter/material.dart';
import 'screens/onboarding.dart';

// app entry
void main() {
  runApp(const MyApp());
}

// root widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Care Plus',
      debugShowCheckedModeBanner: false, 

      theme: ThemeData(
        useMaterial3: true,

        // global colors
        primaryColor: const Color(0xFF2E938A),
        scaffoldBackgroundColor: const Color(0xFFF1FAF9),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E938A),
          background: const Color(0xFFF1FAF9),
        ),
      ),

      home: const OnboardingScreen(), // display onboarding screen on app launch
    );
  }
}
