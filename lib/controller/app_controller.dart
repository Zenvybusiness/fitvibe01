import '../core/engine/decision_engine.dart';
import '../core/engine/learning_engine.dart';
import '../core/models/item.dart';
import '../core/models/user_action.dart';
import '../core/state/preference_state.dart';
import '../data/initial_pool.dart';

class AppController {
  final PreferenceState preferenceState;
  Item? currentItem;
  ActionType lastAction;
  final List<String> recentItems;
  final List<String> recentVibes;
  int actionCount;

  AppController()
      : preferenceState = PreferenceState(),
        currentItem = InitialPool.getItems().first,
        lastAction = ActionType.like,
        recentItems = [],
        recentVibes = [],
        actionCount = 0;

  Item getCurrentItem() {
    return currentItem!;
  }

  void onAction(ActionType action) {
    actionCount += 1;

    LearningEngine.update(preferenceState, currentItem!, action);

    recentItems.add(currentItem!.id);
    if (recentItems.length > 3) {
      recentItems.removeAt(0);
    }

    final String vibe = currentItem!.tags.first;
    recentVibes.add(vibe);
    if (recentVibes.length > 3) {
      recentVibes.removeAt(0);
    }

    if (actionCount < 3) {
      currentItem = InitialPool.getItems()[actionCount % 3];
      lastAction = action;
      return;
    }

    currentItem = DecisionEngine.getNextItem(
      state: preferenceState,
      lastItem: currentItem,
      lastAction: lastAction,
      recentItems: recentItems,
      recentVibes: recentVibes,
      actionCount: actionCount,
    );

    lastAction = action;
  }
}
