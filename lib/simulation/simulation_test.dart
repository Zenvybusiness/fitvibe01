import '../controller/app_controller.dart';
import '../core/models/user_action.dart';

void main() {
  final AppController controller = AppController();
  controller.init();
  final List<ActionType> pattern = [
    ActionType.like,
    ActionType.like,
    ActionType.skip,
    ActionType.like,
    ActionType.skip,
    ActionType.like,
    ActionType.like,
    ActionType.skip,
  ];

  final List<String> last3ItemIds = [];
  final List<String> last3Vibes = [];

  for (int step = 1; step <= 30; step++) {
    final ActionType action = pattern[(step - 1) % pattern.length];
    final item = controller.getCurrentItem();
    final String vibe = item.tags.firstWhere((t) => t.startsWith('vibe:'));
    final String fit = item.tags.firstWhere((t) => t.startsWith('fit:'));

    print('STEP $step | ACTION ${action.name} | ITEM ${item.id} | TAGS ${item.tags}');

    if (last3ItemIds.contains(item.id)) {
      print('ERROR_REPEAT');
    }

    last3ItemIds.add(item.id);
    if (last3ItemIds.length > 3) {
      last3ItemIds.removeAt(0);
    }

    last3Vibes.add(vibe);
    if (last3Vibes.length > 3) {
      last3Vibes.removeAt(0);
    }

    int vibeCount = 0;
    for (final String v in last3Vibes) {
      if (v == vibe) {
        vibeCount++;
      }
    }
    if (vibeCount >= 3) {
      print('ERROR_VIBE_LOOP');
    }

    controller.onAction(action == ActionType.like);
    final nextItem = controller.getCurrentItem();
    final String nextVibe = nextItem.tags.firstWhere((t) => t.startsWith('vibe:'));
    final String nextFit = nextItem.tags.firstWhere((t) => t.startsWith('fit:'));

    final ActionType lastAction = action;
    print(
      'DEBUG | lastAction=${lastAction.name} | last_item_vibe=$vibe | selected_item_vibe=$nextVibe | confidence=${controller.confidence.toStringAsFixed(2)} | likeStreak=${controller.likeStreak} | skipStreak=${controller.skipStreak}',
    );

    final bool reactionOk =
        lastAction == ActionType.like
            ? (nextVibe == vibe || nextFit == fit)
            : (nextVibe != vibe);
    print(reactionOk ? 'REACTION_OK' : 'REACTION_FAIL');

    if (action == ActionType.skip && nextVibe == vibe) {
      print('ERROR_NO_REACTION');
    }

    if (action == ActionType.like) {
      int shared = 0;
      for (final String tag in item.tags) {
        if (nextItem.tags.contains(tag)) {
          shared++;
        }
      }
      if (shared < 2) {
        print('ERROR_WEAK_ALIGNMENT');
      }
    }
  }
}
