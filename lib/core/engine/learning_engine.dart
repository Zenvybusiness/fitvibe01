import '../models/item.dart';
import '../models/user_action.dart';
import '../state/preference_state.dart';

class LearningEngine {
  static void update(
    PreferenceState state,
    Item item,
    ActionType action,
  ) {
    for (final String tag in item.tags) {
      final double weight = state.weights[tag] ?? 1.0;

      if (action == ActionType.like) {
        if (weight < 1.0) {
          state.update(tag, 1.0);
        } else if (weight <= 2.0) {
          state.update(tag, 0.6);
        } else {
          state.update(tag, 0.3);
        }
      }

      if (action == ActionType.skip) {
        state.update(tag, -0.3);
      }
    }

    final List<String> tags = state.weights.keys.toList();
    for (final String tag in tags) {
      state.weights[tag] = (state.weights[tag] ?? 1.0) * 0.98 + 0.02;
    }
  }
}
