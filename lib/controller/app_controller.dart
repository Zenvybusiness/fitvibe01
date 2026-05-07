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
  double confidence = 0.0;
  String preferredVibe = '';

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

    currentItem =
        (nextItem != null && nextItem!.id == resolved.id) ? nextItem : resolved;

    _refreshPreload();

    await _saveState();
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
    preferredVibe = '';
    savedItems.clear();

    state.reset();
    currentItem = Dataset.items.first;
    _refreshPreload();
  }
}
