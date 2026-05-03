import 'package:flutter/material.dart';

import 'tag_chip.dart';

class ItemCard extends StatelessWidget {
  final String imagePath;
  final List<String> tags;

  const ItemCard({
    super.key,
    required this.imagePath,
    this.tags = const <String>[],
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.asset(
                'assets/images/${imagePath.replaceAll(RegExp(r"\\.(png|jpe?g)\$", caseSensitive: false), "")}.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  final String base = imagePath.replaceAll(
                      RegExp(r'\.(png|jpe?g)$', caseSensitive: false), '');
                  return Image.asset(
                    'assets/images/$base.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image, size: 100);
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.map((t) => TagChip(label: t)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
