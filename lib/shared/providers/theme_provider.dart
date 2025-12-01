import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Theme Provider
/// Manages light/dark theme toggle
final themeProvider = StateNotifierProvider<ThemeNotifier, bool>(
  (ref) => ThemeNotifier(),
);

class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier() : super(false); // false = light mode, true = dark mode

  void toggleTheme() {
    state = !state;
  }

  void setLightMode() {
    state = false;
  }

  void setDarkMode() {
    state = true;
  }
}
