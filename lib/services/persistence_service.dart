import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PersistenceService {
  static const _vibeWeightsKey = 'vibeWeights';
  static const _likeStreakKey = 'likeStreak';
  static const _skipStreakKey = 'skipStreak';
  static const _confidenceKey = 'confidence';
  static const _onboardingKey = 'hasSeenOnboarding';
  static const _selectedVibeKey = 'selectedVibe';
  static const _savedItemsKey = 'savedItems';

  //--------------------------------------
  // SAVE
  //--------------------------------------
  static Future<void> saveData({
    required Map<String, int> vibeWeights,
    required int likeStreak,
    required int skipStreak,
    required double confidence,
    required bool hasSeenOnboarding,
    required String selectedVibe,
    required List<String> savedItemIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setString(_vibeWeightsKey, jsonEncode(vibeWeights));
    prefs.setInt(_likeStreakKey, likeStreak);
    prefs.setInt(_skipStreakKey, skipStreak);
    prefs.setDouble(_confidenceKey, confidence);
    prefs.setBool(_onboardingKey, hasSeenOnboarding);
    prefs.setString(_selectedVibeKey, selectedVibe);
    prefs.setStringList(_savedItemsKey, savedItemIds);
  }

  //--------------------------------------
  // LOAD
  //--------------------------------------
  static Future<Map<String, dynamic>> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final vibeWeightsString = prefs.getString(_vibeWeightsKey);

    return {
      "vibeWeights": vibeWeightsString != null
          ? Map<String, int>.from(jsonDecode(vibeWeightsString))
          : <String, int>{},
      "likeStreak": prefs.getInt(_likeStreakKey) ?? 0,
      "skipStreak": prefs.getInt(_skipStreakKey) ?? 0,
      "confidence": prefs.getDouble(_confidenceKey) ?? 0.0,
      "hasSeenOnboarding": prefs.getBool(_onboardingKey) ?? false,
      "selectedVibe": prefs.getString(_selectedVibeKey) ?? "",
      "savedItems": prefs.getStringList(_savedItemsKey) ?? [],
    };
  }
}
