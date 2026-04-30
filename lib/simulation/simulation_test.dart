import '../controller/app_controller.dart';
import '../core/models/user_action.dart';

void main() {
  final AppController controller = AppController();
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

  final List<String> last5ItemIds = [];
  final List<String> last6Vibes = [];

  for (int step = 1; step <= 30; step++) {
    final ActionType action = pattern[(step - 1) % pattern.length];
    final item = controller.getCurrentItem();
    final String vibe = item.tags.first;

    print('STEP $step | ACTION ${action.name} | ITEM ${item.id} | TAGS ${item.tags}');

    if (last5ItemIds.contains(item.id)) {
      print('ERROR_REPEAT');
    }

    last5ItemIds.add(item.id);
    if (last5ItemIds.length > 5) {
      last5ItemIds.removeAt(0);
    }

    last6Vibes.add(vibe);
    if (last6Vibes.length > 6) {
      last6Vibes.removeAt(0);
    }

    int vibeCount = 0;
    for (final String v in last6Vibes) {
      if (v == vibe) {
        vibeCount++;
      }
    }
    if (vibeCount >= 4) {
      print('ERROR_VIBE_LOOP');
    }

    controller.onAction(action);
    final nextItem = controller.getCurrentItem();
    final String nextVibe = nextItem.tags.first;

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
      if (shared < 1) {
        print('ERROR_WEAK_ALIGNMENT');
      }
    }
  }
}
