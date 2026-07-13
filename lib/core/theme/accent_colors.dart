import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccentColor {
  final String name;
  final Color color;
  final Color lightColor;
  final Color darkColor;
  final int seedValue;

  const AccentColor({
    required this.name,
    required this.color,
    required this.lightColor,
    required this.darkColor,
    required this.seedValue,
  });

  MaterialColor get materialColor => Colors.primaries.firstWhere(
    (c) => c.toARGB32() == seedValue,
    orElse: () => Colors.deepPurple,
  );
}

class AccentColors {
  static const String _prefKey = 'accent_color_index';

  static const List<AccentColor> presets = [
    AccentColor(
      name: 'Amethyst',
      color: Color(0xFF9C7BD4),
      lightColor: Color(0xFFB89EE8),
      darkColor: Color(0xFF7E5DB8),
      seedValue: 0xFF7E5DB8,
    ),
    AccentColor(
      name: 'Slate',
      color: Color(0xFF8E9AAF),
      lightColor: Color(0xFFA8B8C9),
      darkColor: Color(0xFF6B7D94),
      seedValue: 0xFF6B7D94,
    ),
    AccentColor(
      name: 'Ember',
      color: Color(0xFFDB9B5A),
      lightColor: Color(0xFFE8B87A),
      darkColor: Color(0xFFC47E3A),
      seedValue: 0xFFC47E3A,
    ),
    AccentColor(
      name: 'Teal',
      color: Color(0xFF5BA8A0),
      lightColor: Color(0xFF7DC0B8),
      darkColor: Color(0xFF3D8E86),
      seedValue: 0xFF3D8E86,
    ),
    AccentColor(
      name: 'Rose',
      color: Color(0xFFC98A9B),
      lightColor: Color(0xFFDDA8B6),
      darkColor: Color(0xFFB06D80),
      seedValue: 0xFFB06D80,
    ),
    AccentColor(
      name: 'Ink',
      color: Color(0xFF8C8C8C),
      lightColor: Color(0xFFA6A6A6),
      darkColor: Color(0xFF6B6B6B),
      seedValue: 0xFF6B6B6B,
    ),
  ];

  static AccentColor get defaultPreset => presets[0];

  static Future<int> getSavedIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefKey) ?? 0;
  }

  static Future<void> saveIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, index.clamp(0, presets.length - 1));
  }

  static Future<AccentColor> getSavedAccent() async {
    final index = await getSavedIndex();
    return presets[index.clamp(0, presets.length - 1)];
  }
}

// Riverpod provider
final accentColorProvider =
    StateNotifierProvider<AccentColorNotifier, AccentColor>((ref) {
  return AccentColorNotifier();
});

class AccentColorNotifier extends StateNotifier<AccentColor> {
  AccentColorNotifier() : super(AccentColors.defaultPreset) {
    _load();
  }

  Future<void> _load() async {
    state = await AccentColors.getSavedAccent();
  }

  Future<void> setAccent(int index) async {
    final color = AccentColors.presets[index.clamp(0, AccentColors.presets.length - 1)];
    state = color;
    await AccentColors.saveIndex(index);
  }
}
