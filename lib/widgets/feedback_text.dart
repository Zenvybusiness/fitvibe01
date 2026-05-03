import 'package:flutter/material.dart';

class FeedbackText extends StatelessWidget {
  final String message;

  const FeedbackText({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) {
      return const SizedBox();
    }
    return Text(message);
  }
}
