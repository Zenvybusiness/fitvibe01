import 'package:flutter/material.dart';

import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        children: [
          const Center(
            child: Text('Discover your style'),
          ),
          const Center(
            child: Text('Tap LIKE or SKIP'),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('We learn your vibe'),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  },
                  child: const Text('Start'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
