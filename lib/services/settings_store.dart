import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

extension AppThemeModeX on AppThemeMode {
  ThemeMode toFlutterThemeMode() {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

class AccentColorOption {
  final String label;
  final Color seed;
  const AccentColorOption(this.label, this.seed);
}

/// Index 0 (Purple) is the "automatic" choice — it matches the app's
/// default brand seed AND is what lets Material You dynamic color (the
/// wallpaper-matched palette) take over on Android 12+. Picking any other
/// preset is a deliberate override of that automatic behavior.
const kAccentColorOptions = [
  AccentColorOption('Purple', Color(0xFF7C4DFF)),
  AccentColorOption('Blue', Color(0xFF1565C0)),
  AccentColorOption('Teal', Color(0xFF00695C)),
  AccentColorOption('Green', Color(0xFF2E7D32)),
  AccentColorOption('Orange', Color(0xFFEF6C00)),
  AccentColorOption('Red', Color(0xFFD32F2F)),
  AccentColorOption('Pink', Color(0xFFD81B60)),
  AccentColorOption('Indigo', Color(0xFF3949AB)),
];

/// App-wide settings, persisted via shared_preferences. A plain
/// ChangeNotifier singleton — [load] must be awaited once at startup
/// before the first frame, so the correct theme shows immediately
/// instead of flashing the default then switching.
class SettingsStore extends ChangeNotifier {
  SettingsStore._internal();
  static final SettingsStore instance = SettingsStore._internal();

  static const _keyThemeMode = 'settings.themeMode';
  static const _keyAccentColorIndex = 'settings.accentColorIndex';
  static const _keyCompactView = 'settings.compactView';
  static const _keyRecycleBinEnabled = 'settings.recycleBinEnabled';
  static const _keyRecycleBinRetentionDays = 'settings.recycleBinRetentionDays';
  static const _keyShowHiddenItems = 'settings.showHiddenItems';
  static const _keyHideFileExtensions = 'settings.hideFileExtensions';
  static const _keyShowFolderSizes = 'settings.showFolderSizes';
  static const _keyDefaultLaunchPath = 'settings.defaultLaunchPath';
  static const _keyTabsEnabled = 'settings.tabsEnabled';
  static const _keySessionRestoreEnabled = 'settings.sessionRestoreEnabled';

  AppThemeMode _themeMode = AppThemeMode.system;
  AppThemeMode get themeMode => _themeMode;

  int _accentColorIndex = 0;
  int get accentColorIndex => _accentColorIndex;

  /// Null means "use Material You / the default brand seed" — see
  /// [kAccentColorOptions]'s doc comment.
  Color? get effectiveAccentSeed =>
      _accentColorIndex == 0 ? null : kAccentColorOptions[_accentColorIndex].seed;

  bool _compactView = false;
  bool get compactView => _compactView;

  bool _recycleBinEnabled = false;
  bool get recycleBinEnabled => _recycleBinEnabled;

  int _recycleBinRetentionDays = 7;
  int get recycleBinRetentionDays => _recycleBinRetentionDays;

  bool _showHiddenItems = false;
  bool get showHiddenItems => _showHiddenItems;

  bool _hideFileExtensions = false;
  bool get hideFileExtensions => _hideFileExtensions;

  bool _showFolderSizes = false;
  bool get showFolderSizes => _showFolderSizes;

  /// Null means the device storage root — the current default behavior.
  String? _defaultLaunchPath;
  String? get defaultLaunchPath => _defaultLaunchPath;

  /// Off by default — this changes the app's whole navigation shell
  /// (StorageGate shows TabsHost instead of a single HomeScreen), so it
  /// doesn't flip on silently for existing users.
  bool _tabsEnabled = false;
  bool get tabsEnabled => _tabsEnabled;

  bool _sessionRestoreEnabled = true;
  bool get sessionRestoreEnabled => _sessionRestoreEnabled;

  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt(_keyThemeMode);
    if (themeIndex != null && themeIndex >= 0 && themeIndex < AppThemeMode.values.length) {
      _themeMode = AppThemeMode.values[themeIndex];
    }

    final accentIndex = prefs.getInt(_keyAccentColorIndex);
    if (accentIndex != null && accentIndex >= 0 && accentIndex < kAccentColorOptions.length) {
      _accentColorIndex = accentIndex;
    }

    _compactView = prefs.getBool(_keyCompactView) ?? false;
    _recycleBinEnabled = prefs.getBool(_keyRecycleBinEnabled) ?? false;
    _recycleBinRetentionDays = prefs.getInt(_keyRecycleBinRetentionDays) ?? 7;
    _showHiddenItems = prefs.getBool(_keyShowHiddenItems) ?? false;
    _hideFileExtensions = prefs.getBool(_keyHideFileExtensions) ?? false;
    _showFolderSizes = prefs.getBool(_keyShowFolderSizes) ?? false;
    _defaultLaunchPath = prefs.getString(_keyDefaultLaunchPath);
    _tabsEnabled = prefs.getBool(_keyTabsEnabled) ?? false;
    _sessionRestoreEnabled = prefs.getBool(_keySessionRestoreEnabled) ?? true;

    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
  }

  Future<void> setAccentColorIndex(int index) async {
    if (index < 0 || index >= kAccentColorOptions.length) return;
    _accentColorIndex = index;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAccentColorIndex, index);
  }

  Future<void> setCompactView(bool value) async {
    _compactView = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCompactView, value);
  }

  Future<void> setRecycleBinEnabled(bool value) async {
    _recycleBinEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRecycleBinEnabled, value);
  }

  Future<void> setRecycleBinRetentionDays(int days) async {
    _recycleBinRetentionDays = days;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRecycleBinRetentionDays, days);
  }

  Future<void> setShowHiddenItems(bool value) async {
    _showHiddenItems = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowHiddenItems, value);
  }

  Future<void> setHideFileExtensions(bool value) async {
    _hideFileExtensions = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHideFileExtensions, value);
  }

  Future<void> setShowFolderSizes(bool value) async {
    _showFolderSizes = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowFolderSizes, value);
  }

  Future<void> setDefaultLaunchPath(String? path) async {
    _defaultLaunchPath = path;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_keyDefaultLaunchPath);
    } else {
      await prefs.setString(_keyDefaultLaunchPath, path);
    }
  }

  Future<void> setTabsEnabled(bool value) async {
    _tabsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTabsEnabled, value);
  }

  Future<void> setSessionRestoreEnabled(bool value) async {
    _sessionRestoreEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySessionRestoreEnabled, value);
  }
}
