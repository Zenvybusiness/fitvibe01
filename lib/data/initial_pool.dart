import '../core/models/item.dart';
import 'dataset.dart';

class InitialPool {
  static List<Item> getItems() {
    return Dataset.items.take(3).toList();
  }
}