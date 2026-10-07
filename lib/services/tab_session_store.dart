import 'package:shared_preferences/shared_preferences.dart';

/// Persists the list of open tabs (each as a path, '' meaning "default
/// start location") and which one was active, so [TabsHost] can restore
/// the same tabs on next launch. Deliberately separate from
/// [SettingsStore] — this is live navigation state that changes on every
/// folder tap, not a user preference.
class TabSessionStore {
  static const _keyPaths = 'tabs.paths';
  static const _keyActiveIndex = 'tabs.activeIndex';

  Future<List<String>> loadPaths() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyPaths) ?? const [];
  }

  Future<int> loadActiveIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyActiveIndex) ?? 0;
  }

  Future<void> save(List<String> paths, int activeIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyPaths, paths);
    await prefs.setInt(_keyActiveIndex, activeIndex);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPaths);
    await prefs.remove(_keyActiveIndex);
  }
}
