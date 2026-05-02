import 'package:flutter/material.dart';

import 'onboarding_screen.dart';

bool _splashDelayStarted = false;

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!_splashDelayStarted) {
      _splashDelayStarted = true;
      Future.delayed(const Duration(seconds: 2), () {
        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const OnboardingScreen(),
          ),
        );
      });
    }

    return const Scaffold(
      body: Center(
        child: Text('FitVibe'),
      ),
    );
  }
}
