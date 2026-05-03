import 'package:flutter/material.dart';

import '../../core/models/item.dart';

class SavedScreen extends StatelessWidget {
  final List<Item> savedItems;

  const SavedScreen({super.key, required this.savedItems});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Styles')),
      body: savedItems.isEmpty
          ? const Center(child: Text('No saved styles yet'))
          : ListView.builder(
              itemCount: savedItems.length,
              itemBuilder: (context, index) {
                final item = savedItems[index];
                return ListTile(
                  title: Text(item.id),
                  subtitle: Text(item.tags.join(', ')),
                );
              },
            ),
    );
  }
}
