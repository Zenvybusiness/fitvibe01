import '../core/engine/decision_engine.dart';
import '../core/models/item.dart';
import '../core/models/user_action.dart';
import '../core/state/preference_state.dart';
import '../data/dataset.dart';

class AppController {
  final PreferenceState state = PreferenceState();
  late Item currentItem;
  List<String> recentItems = [];
  List<String> recentVibes = [];
  int actionCount = 0;
  int skipStreak = 0;
  int likeStreak = 0;
  double confidence = 0.0;

  void init() {
    currentItem = Dataset.items.first;
  }

  Item getCurrentItem() {
    return currentItem;
  }

  void onAction(bool isLike) {
    actionCount++;

    if (isLike) {
      likeStreak += 1;
      skipStreak = 0;
    } else {
      skipStreak += 1;
      likeStreak = 0;
    }

    confidence = (likeStreak * 0.1).clamp(0.0, 1.0);

    recentItems.add(currentItem.id);
    if (recentItems.length > 5) {
      recentItems.removeAt(0);
    }

    final String vibe =
        currentItem.tags.firstWhere((String t) => t.startsWith('vibe:'));
    recentVibes.add(vibe);
    if (recentVibes.length > 5) {
      recentVibes.removeAt(0);
    }

    currentItem = DecisionEngine.getNextItem(
      state: state,
      lastItem: currentItem,
      lastAction: isLike ? ActionType.like : ActionType.skip,
      recentItems: recentItems,
      recentVibes: recentVibes,
      actionCount: actionCount,
      skipStreak: skipStreak,
      likeStreak: likeStreak,
      confidence: confidence,
    );
  }
}
