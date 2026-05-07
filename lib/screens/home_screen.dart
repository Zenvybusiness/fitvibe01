import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controller/app_controller.dart';
import '../../core/engine/decision_engine.dart';
import '../../core/models/item.dart';
import '../../data/dataset.dart';
import '../../services/persistence_service.dart';
import '../widgets/item_card.dart';
import 'profile_screen.dart';
import 'saved_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AppController _controller;
  Item? nextItem;
  double dragX = 0;
  bool isAnimating = false;
  String feedbackText = '';
  double feedbackOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AppController();
    _loadState();
  }

  Future<void> _loadState() async {
    final Map<String, dynamic> data = await PersistenceService.loadData();

    await _controller.init();

    final String selectedVibe = (data['selectedVibe'] as String?) ?? '';
    if (selectedVibe.isNotEmpty && _controller.actionCount == 0) {
      final List<Item> match = Dataset.items.where((Item item) {
        return item.tags.contains('vibe:$selectedVibe');
      }).toList();
      if (match.isNotEmpty) {
        _controller.currentItem = match.first;
      }
    }

    final dynamic savedIdsRaw = data['savedItems'];
    final List<String> savedIds = savedIdsRaw is List
        ? savedIdsRaw.map((dynamic e) => e.toString()).toList()
        : <String>[];
    if (savedIds.isNotEmpty) {
      _controller.savedItems = Dataset.items
          .where((Item item) => savedIds.contains(item.id))
          .toList();
    }

    if (!mounted) {
      return;
    }
    setState(() {
      DecisionEngine.vibeWeights =
          Map<String, int>.from(data['vibeWeights'] as Map? ?? <String, int>{});

      _controller.likeStreak =
          (data['likeStreak'] as num?)?.toInt() ?? 0;
      _controller.skipStreak =
          (data['skipStreak'] as num?)?.toInt() ?? 0;
      _controller.confidence =
          (data['confidence'] as num?)?.toDouble() ?? 0.0;

      nextItem = _controller.peekNextItem();
    });
  }

  Future<void> handleAction(bool isLike) async {
    if (isAnimating) return;

    HapticFeedback.mediumImpact();

    setState(() {
      isAnimating = true;
      feedbackText = isLike ? 'Nice choice' : 'Got it';
      feedbackOpacity = 1.0;
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) {
        return;
      }
      setState(() {
        feedbackOpacity = 0.0;
      });
    });

    await Future.delayed(const Duration(milliseconds: 300));

    await _controller.onAction(isLike);

    await PersistenceService.saveData(
      vibeWeights: DecisionEngine.vibeWeights,
      likeStreak: _controller.likeStreak,
      skipStreak: _controller.skipStreak,
      confidence: _controller.confidence,
      hasSeenOnboarding: true,
      selectedVibe: _controller.preferredVibe,
      savedItemIds: _controller.savedItems.map((Item e) => e.id).toList(),
    );

    await Future.delayed(const Duration(milliseconds: 200));

    setState(() {
      nextItem = _controller.peekNextItem();
      feedbackText = '';
      isAnimating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = _controller.getCurrentItem();
    if (item == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Discover your style"),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SavedScreen(
                    savedItems: _controller.getSavedItems(),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(
                    topVibe: DecisionEngine.getTopVibe(),
                    totalLikes: _controller.totalLikes,
                    confidence: _controller.confidence,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.55,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (nextItem != null)
                      Transform.scale(
                        scale: 0.95,
                        child: Opacity(
                          opacity: 0.6,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/images/${nextItem!.image}',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.broken_image,
                                    size: 100);
                              },
                            ),
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          );
                        },
                        child: GestureDetector(
                          key: ValueKey<String>(item.id),
                          onHorizontalDragUpdate: (DragUpdateDetails details) {
                            setState(() {
                              dragX += details.delta.dx;
                            });
                          },
                          onHorizontalDragEnd: (DragEndDetails details) async {
                            final double vx =
                                details.velocity.pixelsPerSecond.dx;
                            if (!isAnimating) {
                              if (vx > 0) {
                                await handleAction(true);
                              } else if (vx < 0) {
                                await handleAction(false);
                              }
                            }
                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              dragX = 0;
                            });
                          },
                          child: Transform.translate(
                            offset: Offset(dragX, 0),
                            child: Transform.rotate(
                              angle: dragX * 0.001,
                              child: ItemCard(
                                imagePath: item.image,
                                tags: item.tags,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: feedbackOpacity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    feedbackText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: isAnimating ? null : () => handleAction(true),
                    child: const Text('LIKE'),
                  ),
                  ElevatedButton(
                    onPressed: isAnimating ? null : () => handleAction(false),
                    child: const Text('SKIP'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
