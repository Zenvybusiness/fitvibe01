import '../core/models/item.dart';
import 'dataset.dart';

class InitialPool {
  static List<Item> getItems() {
    final List<Item> allItems = Dataset.items;
    if (allItems.isEmpty) {
      return <Item>[];
    }

    Item safePick(String vibe, List<Item> picked) {
      return allItems.firstWhere(
        (item) => item.tags.contains(vibe) && !picked.contains(item),
        orElse: () => allItems.firstWhere(
          (item) => !picked.contains(item),
          orElse: () => allItems.first,
        ),
      );
    }

    final List<Item> result = <Item>[];
    result.add(safePick('vibe:street', result));
    result.add(safePick('vibe:minimal', result));
    result.add(safePick('vibe:casual', result));
    return result;
  }
}