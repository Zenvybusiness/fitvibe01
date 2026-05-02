import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';

void main() {
  runApp(const FanApp());
}

class FanApp extends StatelessWidget {
  const FanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
