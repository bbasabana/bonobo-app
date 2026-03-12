import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/local_storage.dart';

/// Gestion du thème : system (auto) / light / dark.
/// La préférence est sauvegardée en local (Hive) et restaurée au démarrage.
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(LocalStorage.getThemeMode());

  /// Cycle : system → light → dark → system
  void toggle() {
    final next = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    _set(next);
  }

  void setLight() => _set(ThemeMode.light);
  void setDark() => _set(ThemeMode.dark);
  void setSystem() => _set(ThemeMode.system);

  void _set(ThemeMode mode) {
    state = mode;
    LocalStorage.saveThemeMode(mode);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(),
);
