import 'package:flutter/material.dart';

import '../../controller/app_controller.dart';
import '../../core/engine/decision_engine.dart';
import '../../core/models/item.dart';
import '../../data/dataset.dart';
import '../../services/persistence_service.dart';

class StylistScreen extends StatefulWidget {
  const StylistScreen({super.key, this.controller});

  final AppController? controller;

  @override
  State<StylistScreen> createState() => _StylistScreenState();
}

class _StylistScreenState extends State<StylistScreen> {
  late final AppController _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? AppController();
    _prepareController();
  }

  Future<void> _prepareController() async {
    if (widget.controller == null) {
      await _controller.init();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _isReady = true;
    });
  }

  List<Item> _curatedRecommendations(String topVibe) {
    final List<Item> vibeMatches = Dataset.items
        .where((Item item) => DecisionEngine.getVibe(item) == topVibe)
        .take(3)
        .toList();
    if (vibeMatches.length >= 3) {
      return vibeMatches;
    }
    final Set<String> ids = vibeMatches.map((Item item) => item.id).toSet();
    final List<Item> fallback = _controller
        .getStylistRecommendations()
        .where((Item item) => !ids.contains(item.id))
        .toList();
    return <Item>[...vibeMatches, ...fallback].take(3).toList();
  }

  String _cardTitle(Item item) {
    final String vibe =
        DecisionEngine.getVibe(item).replaceFirst('vibe:', '').toUpperCase();
    final String fit = item.tags
        .firstWhere((String tag) => tag.startsWith('fit:'), orElse: () => 'fit:balanced')
        .replaceFirst('fit:', '');
    return '$vibe ${fit[0].toUpperCase()}${fit.substring(1)} Look';
  }

  String _styleInsight(String topVibe) {
    final String fit = _controller
        .getSavedItems()
        .expand((Item item) => item.tags)
        .firstWhere((String tag) => tag.startsWith('fit:'), orElse: () => 'fit:oversized')
        .replaceFirst('fit:', '');
    if (topVibe == 'vibe:minimal') {
      return 'Neutral tones currently match your direction best.';
    }
    if (topVibe == 'vibe:street') {
      return 'Oversized fits improve your confidence trend.';
    }
    return '${fit[0].toUpperCase()}${fit.substring(1)} fits keep your style consistency steady.';
  }

  Future<void> _saveRecommendation(Item item) async {
    final bool alreadySaved =
        _controller.savedItems.any((Item saved) => saved.id == item.id);
    if (alreadySaved) {
      return;
    }

    setState(() {
      _controller.savedItems.add(item);
    });

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
      selectedVibe: _controller.preferredVibe,
      savedItemIds: _controller.savedItems.map((Item e) => e.id).toList(),
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved to your style collection'),
        duration: Duration(milliseconds: 1200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final String topVibe = DecisionEngine.getTopVibe();
    if (topVibe == 'unknown') {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Stylist')),
        body: const Center(
          child: Text('Keep interacting to unlock personalized styling'),
        ),
      );
    }
    final List<Item> recommendations = _curatedRecommendations(topVibe);
    final String vibeLabel = topVibe.replaceFirst('vibe:', '').toUpperCase();
    final String insightText = _styleInsight(topVibe);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Stylist'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Text(
                'AI Stylist',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Personalized recommendations based on your style',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 370,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recommendations.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Item item = recommendations[index];
                    final bool alreadySaved =
                        _controller.savedItems.any((Item saved) => saved.id == item.id);
                    return Container(
                      width: 260,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 14,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 4 / 5,
                                child: Image.asset(
                                  'assets/images/${item.image}',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.broken_image,
                                    size: 64,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _cardTitle(item),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              vibeLabel,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _controller.getRecommendationReason(item),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              DecisionEngine.getVibe(item) == topVibe
                                  ? '+0.2 style alignment'
                                  : 'Improves confidence balance',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const Spacer(),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed:
                                    alreadySaved ? null : () => _saveRecommendation(item),
                                child: Text(alreadySaved ? 'Saved' : 'Save'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x0E000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Style Insight',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      insightText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
