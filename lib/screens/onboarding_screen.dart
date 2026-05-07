import 'package:flutter/material.dart';

import '../../controller/app_controller.dart';
import '../../core/engine/decision_engine.dart';
import '../../services/persistence_service.dart';
import '../ui/screens/main_navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final AppController _controller;
  final List<String> selectedVibes = [];

  @override
  void initState() {
    super.initState();
    _controller = AppController();
    _controller.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Choose your style'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  'street',
                  'casual',
                  'minimal',
                  'formal',
                  'bold',
                ].map((vibe) {
                  final bool selected = selectedVibes.contains(vibe);
                  return FilterChip(
                    label: Text(vibe),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          if (!selectedVibes.contains(vibe)) {
                            selectedVibes.add(vibe);
                          }
                        } else {
                          selectedVibes.remove(vibe);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  _controller.applyInitialPreferences(selectedVibes);
                  final String selectedVibe =
                      selectedVibes.isEmpty ? '' : selectedVibes.first;
                  _controller.preferredVibe = selectedVibe;
                  await _controller.persistState();
                  await PersistenceService.saveData(
                    vibeWeights: DecisionEngine.vibeWeights,
                    likeStreak: _controller.likeStreak,
                    skipStreak: _controller.skipStreak,
                    confidence: _controller.confidence,
                    score: _controller.getScore(),
                    lastUpdatedDay: DateTime.now().day,
                    streakDays: _controller.getStreakDays(),
                    lastOpenedDay: _controller.lastOpenedDay,
                    hasSeenOnboarding: true,
                    selectedVibe: selectedVibe,
                    savedItemIds:
                        _controller.savedItems.map((e) => e.id).toList(),
                  );
                  if (!context.mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const MainNavigationScreen(),
                    ),
                  );
                },
                child: const Text('Start'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
