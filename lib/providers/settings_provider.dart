import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/storage_service.dart';

/// Provider managing application settings: ThemeMode, Gemini AI API key, and Auto-save.
class SettingsProvider extends ChangeNotifier {
  final StorageService _storageService;

  late ThemeMode _themeMode;
  late String _geminiApiKey;
  late bool _useAiExtraction;

  SettingsProvider(this._storageService) {
    _loadSettings();
  }

  ThemeMode get themeMode => _themeMode;
  String get geminiApiKey => _geminiApiKey;
  bool get useAiExtraction => _useAiExtraction;
  bool get hasGeminiKey => _geminiApiKey.trim().isNotEmpty;

  void _loadSettings() {
    final modeStr = _storageService.getThemeMode();
    _themeMode = switch (modeStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    final storedKey = _storageService.getGeminiApiKey();
    if (storedKey.isNotEmpty) {
      _geminiApiKey = storedKey;
    } else {
      _geminiApiKey = dotenv.env['GEMINI_API_KEY'] ??
          const String.fromEnvironment('GEMINI_API_KEY');
    }

    _useAiExtraction = _storageService.getUseAiExtraction() || _geminiApiKey.isNotEmpty;
  }

  /// Updates Theme Mode and persists selection.
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final modeStr = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _storageService.setThemeMode(modeStr);
    notifyListeners();
  }

  /// Updates Gemini API Key and persists it.
  Future<void> setGeminiApiKey(String key) async {
    _geminiApiKey = key.trim();
    await _storageService.setGeminiApiKey(_geminiApiKey);
    notifyListeners();
  }

  /// Toggles AI cloud extraction.
  Future<void> setUseAiExtraction(bool enabled) async {
    _useAiExtraction = enabled;
    await _storageService.setUseAiExtraction(enabled);
    notifyListeners();
  }
}
