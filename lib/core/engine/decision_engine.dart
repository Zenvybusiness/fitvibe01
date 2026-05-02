import '../../data/dataset.dart';
import '../models/item.dart';
import '../models/user_action.dart';
import '../state/preference_state.dart';

class DecisionEngine {
  static String getVibe(Item item) {
    return item.tags.firstWhere(
      (t) => t.startsWith("vibe:"),
      orElse: () => "vibe:unknown",
    );
  }

  static String getFit(Item item) {
    return item.tags.firstWhere(
      (t) => t.startsWith("fit:"),
      orElse: () => "fit:unknown",
    );
  }

  static Item getNextItem({
    required PreferenceState state,
    required Item? lastItem,
    required ActionType lastAction,
    required List<String> recentItems,
    required List<String> recentVibes,
    required int actionCount,
    required int skipStreak,
    required int likeStreak,
    required double confidence,
  }) {
    final List<Item> allItems = List<Item>.from(Dataset.items);

    int overlapCount(Item a, Item b) {
      return a.tags.where((t) => b.tags.contains(t)).length;
    }

    String getVibe(Item item) {
      return item.tags.firstWhere(
        (t) => t.startsWith('vibe:'),
        orElse: () => '',
      );
    }

    // =========================
    // STEP 1: LIGHT FILTER
    // =========================
    List<Item> filtered = allItems;

    if (lastItem != null) {
      filtered = allItems.where((item) {
        final overlap = overlapCount(item, lastItem);

        if (lastAction == ActionType.like) {
          return overlap >= 1;
        } else {
          return overlap <= 1;
        }
      }).toList();

      if (filtered.length < 3) {
        filtered = allItems;
      }
    }

    final List<String> last3 = recentItems.length >= 3
        ? recentItems.sublist(recentItems.length - 3)
        : recentItems;
    final Set<String> recentSet = last3.toSet();
    final List<Item> hardRepeatFiltered =
        filtered.where((item) => !recentSet.contains(item.id)).toList();
    final List<Item> candidates =
        hardRepeatFiltered.isEmpty ? filtered : hardRepeatFiltered;

    // =========================
    // STEP 2: SCORING
    // =========================
    final scored = candidates.map((item) {
      double score = 0.1 + state.getScore(item.tags);

      // soft repeat penalty
      if (recentItems.contains(item.id)) {
        score *= 0.5;
      }

      if (lastItem != null) {
        final overlap = overlapCount(item, lastItem);

        if (lastAction == ActionType.like) {
          score += overlap * 2.0;

          if (overlap == 0) {
            score *= 0.5;
          }
        } else {
          score -= overlap * 0.5;

          if (overlap == 0) {
            score += 1.0;
          }
        }

        if (overlap >= 3) {
          score *= 0.7;
        }
      }

      // vibe control (soft)
      final vibe = getVibe(item);
      final vibeCount = recentVibes.where((v) => v == vibe).length;

      if (vibeCount >= 3) {
        score *= 0.7;
      }

      if (score < 0) score = 0;

      return MapEntry(item, score);
    }).toList();

    // =========================
    // STEP 3: SORT + TOP
    // =========================
    scored.sort((a, b) => b.value.compareTo(a.value));

    final topItems = scored
        .take(scored.length < 5 ? scored.length : 5)
        .map((e) => e.key)
        .toList();

    bool isWowTime = (actionCount % 6 == 0);
    if (isWowTime) {
      for (final item in allItems) {
        final vibe = getVibe(item);
        final isRareVibe = vibe == 'vibe:bold' ||
            vibe == 'vibe:formal' ||
            vibe == 'vibe:sporty';
        if (!recentItems.contains(item.id) && isRareVibe) {
          return item;
        }
      }
    }

    List<Item> validPool = topItems;
    if (lastItem != null) {
      final String lastVibe = DecisionEngine.getVibe(lastItem);
      final String lastFit = DecisionEngine.getFit(lastItem);

      if (lastAction == ActionType.like) {
        validPool = topItems.where((item) {
          return item.tags.contains(lastVibe) || item.tags.contains(lastFit);
        }).toList();
      }

      if (lastAction == ActionType.skip) {
        validPool = topItems.where((item) {
          return !item.tags.contains(lastVibe);
        }).toList();
      }
    }

    if (validPool.isEmpty) {
      validPool = topItems;
    }

    if (topItems.isEmpty) {
      return allItems.first;
    }

    // =========================
    // STEP 4: SELECTION
    // =========================
    final List<Item> confidencePool = confidence > 0.7
        ? validPool.take(validPool.length >= 2 ? 2 : validPool.length).toList()
        : confidence < 0.3
            ? validPool
                .take(validPool.length >= 4 ? 4 : validPool.length)
                .toList()
            : validPool;
    final List<Item> selectionPool = likeStreak >= 2
        ? confidencePool
            .take(confidencePool.length >= 2 ? 2 : confidencePool.length)
            .toList()
        : confidencePool;
    final List<String> last4Vibes = recentVibes.length <= 4
        ? recentVibes
        : recentVibes.sublist(recentVibes.length - 4);
    String blockedVibe = '';
    for (final String vibe in last4Vibes) {
      final int count = last4Vibes.where((v) => v == vibe).length;
      if (count >= 3) {
        blockedVibe = vibe;
        break;
      }
    }
    final List<Item> vibeSafePool = blockedVibe.isNotEmpty
        ? selectionPool.where((item) => getVibe(item) != blockedVibe).toList()
        : selectionPool;
    final List<Item> activeSelectionPool =
        vibeSafePool.isEmpty ? selectionPool : vibeSafePool;
    Item selected;

    if (actionCount < 5) {
      selected = activeSelectionPool[actionCount % activeSelectionPool.length];
    } else {
      selected = activeSelectionPool[0];
    }

    if (skipStreak >= 3) {
      final List<Item> explorationPool = blockedVibe.isNotEmpty
          ? validPool.where((item) => getVibe(item) != blockedVibe).toList()
          : validPool;
      final List<Item> activeExplorationPool =
          explorationPool.isEmpty ? validPool : explorationPool;
      if (activeExplorationPool.length > 3) {
        selected = activeExplorationPool[actionCount % 2 == 0 ? 2 : 3];
      } else if (activeExplorationPool.length > 2) {
        selected = activeExplorationPool[2];
      } else {
        selected = activeExplorationPool.last;
      }
    }

    // =========================
    // STEP 5: SOFT ENFORCEMENT
    // =========================
    if (lastItem != null) {
      final lastVibe = getVibe(lastItem);

      for (final item in activeSelectionPool) {
        final vibe = getVibe(item);

        if (lastAction == ActionType.like && vibe == lastVibe) {
          selected = item;
          break;
        }

        if (lastAction == ActionType.skip && vibe != lastVibe) {
          selected = item;
          break;
        }
      }

      // final repeat safety
      for (final item in activeSelectionPool) {
        if (!recentItems.contains(item.id)) {
          selected = item;
          break;
        }
      }

      if (lastAction == ActionType.like) {
        final String lastVibe = DecisionEngine.getVibe(lastItem);
        final String lastFit = DecisionEngine.getFit(lastItem);
        final String selectedVibe = DecisionEngine.getVibe(selected);
        final String selectedFit = DecisionEngine.getFit(selected);
        final bool isValidLikeSelection =
            selectedVibe == lastVibe || selectedFit == lastFit;

        if (!isValidLikeSelection) {
          bool found = false;
          for (final item in validPool) {
            final bool isValidMatch =
                DecisionEngine.getVibe(item) == lastVibe ||
                    DecisionEngine.getFit(item) == lastFit;
            if (isValidMatch) {
              selected = item;
              found = true;
              break;
            }
          }
          if (!found) {
            selected = validPool.first;
          }
        }
      }

      if (lastAction == ActionType.skip) {
        final String lastVibe = DecisionEngine.getVibe(lastItem);
        final String selectedVibe = DecisionEngine.getVibe(selected);

        if (selectedVibe == lastVibe) {
          bool found = false;
          for (final item in validPool) {
            if (DecisionEngine.getVibe(item) != lastVibe) {
              selected = item;
              found = true;
              break;
            }
          }
          if (!found) {
            selected = validPool.last;
          }
        }
      }
    }

    return selected;
  }
}
