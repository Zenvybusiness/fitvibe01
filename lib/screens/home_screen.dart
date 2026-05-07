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
  double cardRotation = 0;
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
      dragX = 0;
      cardRotation = 0;
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double maxCardHeight = (MediaQuery.of(context)
                                .size
                                .height *
                            0.58)
                        .clamp(280.0, constraints.maxHeight);
                    return Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: maxCardHeight,
                          maxWidth: 520,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (nextItem != null)
                                Positioned.fill(
                                  child: Transform.scale(
                                    scale: 0.96,
                                    child: Opacity(
                                      opacity: 0.45,
                                      child: IgnorePointer(
                                        child: ItemCard(
                                          imagePath: nextItem!.image,
                                          tags: nextItem!.tags,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned.fill(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 360),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  layoutBuilder: (
                                    Widget? currentChild,
                                    List<Widget> previousChildren,
                                  ) {
                                    return Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ...previousChildren,
                                        if (currentChild != null) currentChild,
                                      ],
                                    );
                                  },
                                  transitionBuilder: (
                                    Widget child,
                                    Animation<double> animation,
                                  ) {
                                    final bool isIncoming =
                                        child.key == ValueKey<String>(item.id);
                                    final Animation<Offset> slideAnimation =
                                        Tween<Offset>(
                                      begin: isIncoming
                                          ? const Offset(1, 0)
                                          : Offset.zero,
                                      end: isIncoming
                                          ? Offset.zero
                                          : const Offset(-1, 0),
                                    ).animate(animation);
                                    final Animation<double> fadeAnimation =
                                        Tween<double>(
                                      begin: isIncoming ? 0.95 : 1.0,
                                      end: isIncoming ? 1.0 : 0.75,
                                    ).animate(animation);
                                    final Animation<double> rotateAnimation =
                                        Tween<double>(
                                      begin: isIncoming ? 0.03 : 0.0,
                                      end: isIncoming ? 0.0 : -0.03,
                                    ).animate(animation);
                                    return SlideTransition(
                                      position: slideAnimation,
                                      child: FadeTransition(
                                        opacity: fadeAnimation,
                                        child: AnimatedBuilder(
                                          animation: rotateAnimation,
                                          builder: (context, childWidget) {
                                            return Transform.rotate(
                                              angle: rotateAnimation.value,
                                              child: childWidget,
                                            );
                                          },
                                          child: child,
                                        ),
                                      ),
                                    );
                                  },
                                  child: GestureDetector(
                                    key: ValueKey<String>(item.id),
                                    onHorizontalDragUpdate:
                                        (DragUpdateDetails details) {
                                      if (isAnimating) {
                                        return;
                                      }
                                      setState(() {
                                        dragX += details.delta.dx;
                                        cardRotation = (dragX * 0.0015)
                                            .clamp(-0.08, 0.08);
                                      });
                                    },
                                    onHorizontalDragEnd:
                                        (DragEndDetails details) async {
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
                                        cardRotation = 0;
                                      });
                                    },
                                    child: Transform.translate(
                                      offset: Offset(dragX, 0),
                                      child: Transform.rotate(
                                        angle: cardRotation,
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
                      ),
                    );
                  },
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: feedbackOpacity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    feedbackText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
