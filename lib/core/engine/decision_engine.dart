import '../../data/dataset.dart';
import '../models/item.dart';
import '../models/user_action.dart';
import '../state/preference_state.dart';

class DecisionEngine {
  static Item getNextItem({
    required PreferenceState state,
    required Item? lastItem,
    required ActionType lastAction,
    required List<String> recentItems,
    required List<String> recentVibes,
    required int actionCount,
  }) {

    final List<Item> candidates = List<Item>.from(Dataset.items);

    // ===============================
    // STEP 1: SCORING ONLY (NO FILTER)
    // ===============================
    final List<MapEntry<Item, double>> scored = candidates.map((item) {
      double score = 0.1 + state.getScore(item.tags);

      // ❗ reduce repeat
      if (recentItems.contains(item.id)) {
        score *= 0.2;
      }

      if (lastItem != null) {
        final overlap =
            item.tags.where((t) => lastItem.tags.contains(t)).length;

        // ✅ LIKE → enforce similarity
        if (lastAction == ActionType.like) {
          score += overlap * 2.0;

          if (overlap == 0) {
            score *= 0.3;
          }
        }

        // ✅ SKIP → HARD reaction
        if (lastAction == ActionType.skip) {
          score -= overlap * 2.0;

          final lastVibe = lastItem.tags
              .firstWhere((t) => t.startsWith("vibe:"), orElse: () => "");

          final currentVibe = item.tags
              .firstWhere((t) => t.startsWith("vibe:"), orElse: () => "");

          if (currentVibe == lastVibe) {
            score *= 0.2;
          }
        }

        // similarity penalty
        if (overlap >= 2) {
          score *= 0.7;
        }

        final uniqueTags =
            item.tags.where((t) => !lastItem.tags.contains(t)).length;

        score += uniqueTags * 0.2;
      }

      //  VIBE LOOP KILL
      final vibe = item.tags
          .firstWhere((t) => t.startsWith("vibe:"), orElse: () => "");

      final vibeCount = recentVibes.where((v) => v == vibe).length;

      if (vibeCount >= 2) {
        score *= 0.3; // strong block
      }

      if (score < 0) score = 0;

      return MapEntry(item, score);
    }).toList();

    // ===============================
    // STEP 2: SORT
    // ===============================
    scored.sort((a, b) => b.value.compareTo(a.value));

    final List<Item> topItems =
        scored.take(5).map((e) => e.key).toList();

    // ===============================
    // STEP 3: NO RANDOMNESS
    // ===============================
    Item selected = topItems.first;

    // ===============================
    // STEP 4: FINAL SAFETY ONLY
    // ===============================
    if (recentItems.contains(selected.id)) {
      for (final item in topItems) {
        if (!recentItems.contains(item.id)) {
          selected = item;
          break;
        }
      }
    }

    return selected;
  }
}