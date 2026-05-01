import 'package:flutter/material.dart';

import '../../controller/app_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppController();
    _controller.init();
  }

  @override
  Widget build(BuildContext context) {
    final item = _controller.getCurrentItem();
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('ID: ${item.id}'),
            Text('Tags: ${item.tags.join(', ')}'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    _controller.onAction(true);
                    setState(() {});
                  },
                  child: const Text('LIKE'),
                ),
                TextButton(
                  onPressed: () {
                    _controller.onAction(false);
                    setState(() {});
                  },
                  child: const Text('SKIP'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
