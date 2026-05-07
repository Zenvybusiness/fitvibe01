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
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double imageHeight = (constraints.maxHeight * 0.72)
                .clamp(180.0, constraints.maxHeight);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: imageHeight,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                    child: Image.asset(
                      'assets/images/${imagePath.replaceAll(RegExp(r"\\.(png|jpe?g)\$", caseSensitive: false), "")}.jpg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        final String base = imagePath.replaceAll(
                            RegExp(r'\.(png|jpe?g)$', caseSensitive: false), '');
                        return Image.asset(
                          'assets/images/$base.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.broken_image, size: 100);
                          },
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tags.map((t) => TagChip(label: t)).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
