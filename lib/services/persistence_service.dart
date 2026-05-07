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
  static const _scoreKey = 'score';
  static const _lastUpdatedDayKey = 'lastUpdatedDay';
  static const _streakDaysKey = 'streakDays';
  static const _lastOpenedDayKey = 'lastOpenedDay';

  //--------------------------------------
  // SAVE
  //--------------------------------------
  static Future<void> saveData({
    required Map<String, int> vibeWeights,
    required int likeStreak,
    required int skipStreak,
    required double confidence,
    required double score,
    required int lastUpdatedDay,
    required int streakDays,
    required int lastOpenedDay,
    required bool hasSeenOnboarding,
    required String selectedVibe,
    required List<String> savedItemIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setString(_vibeWeightsKey, jsonEncode(vibeWeights));
    prefs.setInt(_likeStreakKey, likeStreak);
    prefs.setInt(_skipStreakKey, skipStreak);
    prefs.setDouble(_confidenceKey, confidence);
    prefs.setDouble(_scoreKey, score);
    prefs.setInt(_lastUpdatedDayKey, lastUpdatedDay);
    prefs.setInt(_streakDaysKey, streakDays);
    prefs.setInt(_lastOpenedDayKey, lastOpenedDay);
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
      "score": prefs.getDouble(_scoreKey) ?? 5.5,
      "lastUpdatedDay": prefs.getInt(_lastUpdatedDayKey) ?? DateTime.now().day,
      "streakDays": prefs.getInt(_streakDaysKey) ?? 1,
      "lastOpenedDay": prefs.getInt(_lastOpenedDayKey) ?? DateTime.now().day,
      "hasSeenOnboarding": prefs.getBool(_onboardingKey) ?? false,
      "selectedVibe": prefs.getString(_selectedVibeKey) ?? "",
      "savedItems": prefs.getStringList(_savedItemsKey) ?? [],
    };
  }
}
