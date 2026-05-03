import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/persistence_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final Map<String, dynamic> initialData = await PersistenceService.loadData();
  final bool hasSeenOnboarding =
      initialData['hasSeenOnboarding'] as bool? ?? false;
  runApp(FanApp(hasSeenOnboarding: hasSeenOnboarding));
}

class FanApp extends StatelessWidget {
  const FanApp({super.key, required this.hasSeenOnboarding});

  final bool hasSeenOnboarding;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: hasSeenOnboarding ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}
