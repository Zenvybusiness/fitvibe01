import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final String topVibe;
  final int totalLikes;
  final double confidence;

  const ProfileScreen({
    super.key,
    required this.topVibe,
    required this.totalLikes,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Top Vibe: $topVibe'),
          Text('Total Likes: $totalLikes'),
          Text('Confidence: ${confidence.toStringAsFixed(2)}'),
        ],
      ),
    );
  }
}
