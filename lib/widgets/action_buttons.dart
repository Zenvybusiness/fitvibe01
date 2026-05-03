import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onLike;
  final VoidCallback onSkip;

  const ActionButtons({
    super.key,
    required this.onLike,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: TextButton(
            onPressed: onLike,
            child: const Text('LIKE'),
          ),
        ),
        Expanded(
          child: TextButton(
            onPressed: onSkip,
            child: const Text('SKIP'),
          ),
        ),
      ],
    );
  }
}
