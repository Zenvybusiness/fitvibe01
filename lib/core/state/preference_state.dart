class PreferenceState {
  final Map<String, double> weights = {};

  double getScore(List<String> tags) {
    if (tags.isEmpty) {
      return 0;
    }

    double total = 0;
    for (final tag in tags) {
      total += weights[tag] ?? 1.0;
    }
    return total / tags.length;
  }

  void update(String tag, double value) {
    final double current = weights[tag] ?? 1.0;
    double next = current + value;
    if (next < 0.5) {
      next = 0.5;
    } else if (next > 3.0) {
      next = 3.0;
    }
    weights[tag] = next;
  }

  void increaseWeight(String tag, double value) {
    update(tag, value);
  }

  Map<String, dynamic> toJson() {
    return {
      'weights': weights,
    };
  }

  void fromJson(Map<String, dynamic> json) {
    final dynamic raw = json['weights'] ?? {};
    final Map<dynamic, dynamic> map = raw is Map ? raw : <dynamic, dynamic>{};
    weights
      ..clear()
      ..addAll(
        map.map(
          (key, value) => MapEntry(
            key.toString(),
            (value is num ? value.toDouble() : 1.0),
          ),
        ),
      );
  }

  void reset() {
    weights.clear();
  }
}
