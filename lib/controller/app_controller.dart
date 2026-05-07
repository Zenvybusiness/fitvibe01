import '../core/engine/decision_engine.dart';
import '../core/models/item.dart';
import '../core/models/user_action.dart';
import '../core/state/preference_state.dart';
import '../data/dataset.dart';
import '../services/persistence_service.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AppController {
  static const String _prefsKey = 'user_state';

  final PreferenceState state = PreferenceState();
  Item? currentItem;
  Item? nextItem;
  String? _preloadSourceItemId;
  List<Item> savedItems = [];
  List<String> recentItems = [];
  List<String> recentVibes = [];
  int actionCount = 0;
  int totalLikes = 0;
  int skipStreak = 0;
  int likeStreak = 0;
  int streakDays = 1;
  int lastOpenedDay = DateTime.now().day;
  double confidence = 0.0;
  double score = 5.5;
  double lastDelta = 0.0;
  double yesterdayScore = 5.5;
  String preferredVibe = '';
  Map<String, dynamic>? lastStyleAnalysis;

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();

    final data = {
      'recentItems': recentItems,
      'recentVibes': recentVibes,
      'actionCount': actionCount,
      'totalLikes': totalLikes,
      'likeStreak': likeStreak,
      'skipStreak': skipStreak,
      'confidence': confidence,
      'score': score,
      'lastDelta': lastDelta,
      'yesterdayScore': yesterdayScore,
      'preferredVibe': preferredVibe,
      'savedItemIds': savedItems.map((Item e) => e.id).toList(),
      'preferences': state.toJson(),
    };

    prefs.setString(_prefsKey, jsonEncode(data));
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefsKey);

    if (jsonString == null) return;

    final dynamic decoded = jsonDecode(jsonString);
    final Map<String, dynamic> data =
        decoded is Map ? Map<String, dynamic>.from(decoded) : <String, dynamic>{};

    recentItems = List<String>.from(data['recentItems'] ?? []);
    recentVibes = List<String>.from(data['recentVibes'] ?? []);
    actionCount = data['actionCount'] ?? 0;
    totalLikes = data['totalLikes'] ?? 0;
    likeStreak = data['likeStreak'] ?? 0;
    skipStreak = data['skipStreak'] ?? 0;
    confidence = (data['confidence'] ?? 0).toDouble();
    score = (data['score'] ?? 5.5).toDouble();
    lastDelta = (data['lastDelta'] ?? 0.0).toDouble();
    yesterdayScore = (data['yesterdayScore'] ?? score).toDouble();
    final String rawPreferred = (data['preferredVibe'] ?? '').toString();
    preferredVibe = rawPreferred.startsWith('vibe:')
        ? rawPreferred.substring('vibe:'.length)
        : rawPreferred;

    savedItems = [];
    final dynamic rawSaved = data['savedItemIds'];
    if (rawSaved is List) {
      for (final dynamic id in rawSaved) {
        final String sid = id.toString();
        for (final Item item in Dataset.items) {
          if (item.id == sid) {
            savedItems.add(item);
            break;
          }
        }
      }
    }

    final dynamic prefsJson = data['preferences'] ?? {};
    state.fromJson(
      prefsJson is Map ? Map<String, dynamic>.from(prefsJson) : <String, dynamic>{},
    );
  }

  String _preferredVibeTag() =>
      preferredVibe.isEmpty ? '' : 'vibe:$preferredVibe';

  void _refreshPreload() {
    if (currentItem == null) {
      nextItem = null;
      _preloadSourceItemId = null;
      return;
    }
    nextItem = DecisionEngine.getNextItem(
      state: state,
      lastItem: currentItem,
      lastAction: ActionType.like,
      recentItems: recentItems,
      recentVibes: recentVibes,
      actionCount: actionCount,
      skipStreak: skipStreak,
      likeStreak: likeStreak,
      confidence: confidence,
      preferredVibe: _preferredVibeTag(),
      recordVibeWeights: false,
    );
    _preloadSourceItemId = currentItem!.id;
  }

  Future<void> init() async {
    await _loadState();
    updateStreak();

    final Map<String, dynamic> learningData =
        await PersistenceService.loadData();
    DecisionEngine.vibeWeights = Map<String, int>.from(
      learningData['vibeWeights'] as Map? ?? <String, int>{},
    );

    final String dominantVibe = DecisionEngine.getTopVibe();

    if (dominantVibe.isNotEmpty && dominantVibe != 'unknown') {
      final List<Item> match = Dataset.items.where((Item item) {
        return item.tags.contains(dominantVibe);
      }).toList();

      if (match.isNotEmpty) {
        currentItem = match.first;
      }
    }

    currentItem ??= Dataset.items.first;
    _refreshPreload();
  }

  Future<void> persistState() async => _saveState();

  Item? getCurrentItem() {
    return currentItem;
  }

  List<Item> getSavedItems() => savedItems;

  List<Item> getStylistRecommendations() {
    final String topVibe = DecisionEngine.getTopVibe();
    final Set<String> savedTags = savedItems
        .expand((Item item) => item.tags)
        .where((String tag) => tag.startsWith('fit:') || tag.startsWith('vibe:'))
        .toSet();

    final List<MapEntry<Item, double>> scored = Dataset.items.map((Item item) {
      double value = 0;
      final String itemVibe = DecisionEngine.getVibe(item);

      if (topVibe != 'unknown' && itemVibe == topVibe) {
        value += 3.0;
      }
      if (preferredVibe.isNotEmpty && itemVibe == 'vibe:$preferredVibe') {
        value += 2.0;
      }
      for (final String tag in item.tags) {
        if (savedTags.contains(tag)) {
          value += 0.5;
        }
      }
      if (savedItems.any((Item saved) => saved.id == item.id)) {
        value -= 2.0;
      }
      return MapEntry<Item, double>(item, value);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).take(4).toList();
  }

  Item peekNextItem() {
    final Item? cur = currentItem;
    if (cur != null &&
        nextItem != null &&
        _preloadSourceItemId == cur.id) {
      return nextItem!;
    }
    _refreshPreload();
    return nextItem!;
  }

  void applyInitialPreferences(List<String> vibes) {
    for (var vibe in vibes) {
      state.increaseWeight('vibe:$vibe', 2.0);
    }
  }

  void updateStreak() {
    final int today = DateTime.now().day;
    if (today != lastOpenedDay) {
      if (today - lastOpenedDay == 1) {
        streakDays++;
      } else {
        streakDays = 1;
      }
      lastOpenedDay = today;
    }
  }

  Future<void> onAction(bool isLike) async {
    actionCount++;

    final Item fromItem = currentItem!;

    if (isLike) {
      likeStreak += 1;
      skipStreak = 0;
      totalLikes += 1;
      if (!savedItems.contains(fromItem)) {
        savedItems.add(fromItem);
      }
    } else {
      skipStreak += 1;
      likeStreak = 0;
    }

    confidence = (likeStreak * 0.1).clamp(0.0, 1.0);

    recentItems.add(fromItem.id);
    if (recentItems.length > 5) {
      recentItems.removeAt(0);
    }

    final String vibe =
        fromItem.tags.firstWhere((String t) => t.startsWith('vibe:'));
    recentVibes.add(vibe);
    if (recentVibes.length > 5) {
      recentVibes.removeAt(0);
    }

    final Item resolved = DecisionEngine.getNextItem(
      state: state,
      lastItem: fromItem,
      lastAction: isLike ? ActionType.like : ActionType.skip,
      recentItems: recentItems,
      recentVibes: recentVibes,
      actionCount: actionCount,
      skipStreak: skipStreak,
      likeStreak: likeStreak,
      confidence: confidence,
      preferredVibe: _preferredVibeTag(),
      recordVibeWeights: true,
    );

    // Basic scoring logic
    double delta = 0.0;
    final String? currentVibeTag = fromItem.tags.cast<String?>().firstWhere(
          (String? t) => t != null && t.startsWith('vibe:'),
          orElse: () => null,
        );
    if (isLike) {
      if (DecisionEngine.getTopVibe() == currentVibeTag) {
        delta = 0.2;
      } else {
        delta = 0.1;
      }
    } else {
      delta = -0.05;
    }
    score = (score + delta).clamp(3.0, 9.0);
    lastDelta = delta;

    currentItem =
        (nextItem != null && nextItem!.id == resolved.id) ? nextItem : resolved;

    _refreshPreload();

    await _saveState();
  }

  double getScore() => score;
  double getLastDelta() => lastDelta;
  int getStreakDays() => streakDays;

  String getFeedbackMessage() {
    if (lastDelta > 0.15) {
      return "+0.2 — strong style alignment";
    } else if (lastDelta > 0) {
      return "+0.1 — slight improvement";
    } else {
      return "-0.05 — weak match";
    }
  }

  String getProgressMessage() {
    final double diff = score - yesterdayScore;

    if (diff > 0.2) return "You improved today";
    if (diff > 0) return "Slight improvement";
    if (diff < -0.2) return "Performance dropped";
    return "Stable";
  }

  bool shouldShowSummary() => actionCount >= 10;

  void resetSession() {
    actionCount = 0;
  }

  int getPercentile() {
    return (score * 10).toInt();
  }

  String getComparisonText() {
    final int p = getPercentile();

    if (p > 80) return "Top 20%";
    if (p > 60) return "Above average";
    if (p > 40) return "Average";
    return "Below average";
  }

  Map<String, dynamic> analyzeStyle() {
    final String topVibeTag = DecisionEngine.getTopVibe();
    final String resolvedVibe = topVibeTag.startsWith('vibe:')
        ? topVibeTag.substring('vibe:'.length)
        : (preferredVibe.isNotEmpty ? preferredVibe : 'minimal');

    final Set<String> fitPool = <String>{};
    for (final Item item in savedItems) {
      for (final String tag in item.tags) {
        if (tag.startsWith('fit:')) {
          fitPool.add(tag.substring('fit:'.length));
        }
      }
    }
    if (fitPool.isEmpty) {
      fitPool.add('oversized');
    }
    final String preferredFit = fitPool.first;

    final String faceShape;
    if (resolvedVibe == 'minimal') {
      faceShape = 'oval';
    } else if (resolvedVibe == 'street') {
      faceShape = 'square';
    } else if (resolvedVibe == 'formal') {
      faceShape = 'oblong';
    } else {
      faceShape = 'round';
    }

    final double confidenceScore =
        (score + (confidence * 1.5) + (lastDelta > 0 ? 0.2 : 0.0))
            .clamp(4.5, 9.0);

    final Map<String, dynamic> result = <String, dynamic>{
      'vibe': resolvedVibe,
      'fit': preferredFit,
      'confidence': confidenceScore,
      'faceShape': faceShape,
    };
    lastStyleAnalysis = result;
    return result;
  }

  List<String> getHairstyleSuggestions() {
    final Map<String, dynamic> analysis = lastStyleAnalysis ?? analyzeStyle();
    final String vibe = (analysis['vibe'] as String? ?? 'minimal').toLowerCase();
    final String faceShape =
        (analysis['faceShape'] as String? ?? 'oval').toLowerCase();
    final double analysisConfidence =
        (analysis['confidence'] as num?)?.toDouble() ?? 6.0;

    final List<String> styles = <String>[];
    if (vibe == 'minimal') {
      styles.addAll(<String>['Textured Crop', 'Clean Fade']);
    } else if (vibe == 'street') {
      styles.addAll(<String>['Modern Fringe', 'Layered Flow']);
    } else {
      styles.addAll(<String>['Classic Taper', 'Soft Side Part']);
    }

    if (faceShape == 'oval' || faceShape == 'oblong') {
      styles.add('Balanced Medium Layers');
    } else {
      styles.add('Structured Volume Top');
    }

    if (analysisConfidence < 6.0) {
      styles.add('Low-Maintenance Crop');
    } else {
      styles.add('Clean Textured Quiff');
    }

    return styles.take(4).toList();
  }

  List<String> getImprovementTips() {
    final Map<String, dynamic> analysis = lastStyleAnalysis ?? analyzeStyle();
    final String vibe = (analysis['vibe'] as String? ?? 'minimal').toLowerCase();

    final List<String> tips = <String>[];
    if (vibe == 'minimal') {
      tips.add('Try cleaner neutral tones for stronger consistency');
      tips.add('Keep silhouettes simple and reduce extra layering');
    } else if (vibe == 'street') {
      tips.add('Use one statement layer and keep the base clean');
      tips.add('Oversized fits match your current style direction');
    } else {
      tips.add('Balance structured pieces with softer basics');
      tips.add('Focus on fit consistency before adding bold accents');
    }

    if (score < 6.0) {
      tips.add('Start with repeatable outfit formulas for daily consistency');
    } else {
      tips.add('Refine details like footwear and accessories for polish');
    }

    if (confidence < 0.4) {
      tips.add('Limit major style switches and build one clear direction');
    } else {
      tips.add('Maintain your strongest vibe and test one variation weekly');
    }

    return tips.take(4).toList();
  }

  Future<void> applyAnalysisToSystem(Map<String, dynamic> analysis) async {
    final String vibe = (analysis['vibe'] as String? ?? '').trim();
    final String fit = (analysis['fit'] as String? ?? '').trim();

    if (vibe.isNotEmpty) {
      final String vibeTag = 'vibe:$vibe';
      state.increaseWeight(vibeTag, 0.25);
      DecisionEngine.vibeWeights[vibeTag] =
          (DecisionEngine.vibeWeights[vibeTag] ?? 0) + 1;
      preferredVibe = preferredVibe.isEmpty ? vibe : preferredVibe;
    }
    if (fit.isNotEmpty) {
      state.increaseWeight('fit:$fit', 0.2);
    }

    lastStyleAnalysis = analysis;
    await _saveState();
  }

  String getRecommendationReason(Item item) {
    final String topVibe = DecisionEngine.getTopVibe();
    final String itemVibe = DecisionEngine.getVibe(item);
    if (topVibe != 'unknown' && itemVibe == topVibe) {
      return "Matches your strongest style preference";
    }

    final Set<String> likedFits = savedItems
        .expand((Item saved) => saved.tags)
        .where((String tag) => tag.startsWith('fit:'))
        .toSet();
    final bool fitAligned = item.tags.any((String tag) => likedFits.contains(tag));
    if (fitAligned) {
      return "Consistent with your preferred fit";
    }

    return "Suggested to expand your style range";
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);

    recentItems.clear();
    recentVibes.clear();
    actionCount = 0;
    totalLikes = 0;
    likeStreak = 0;
    skipStreak = 0;
    confidence = 0;
    score = 5.5;
    lastDelta = 0.0;
    yesterdayScore = 5.5;
    preferredVibe = '';
    savedItems.clear();

    state.reset();
    currentItem = Dataset.items.first;
    _refreshPreload();
  }
}
