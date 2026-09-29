import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/lead_model.dart';

/// Storage service providing persistent local caching of Leads, Settings, and Gemini Keys.
class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  /// Initializes StorageService instance with SharedPreferences.
  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // -------------------------------------------------------------
  // LEADS PERSISTENCE
  // -------------------------------------------------------------

  /// Retrieves all saved leads sorted newest first.
  List<LeadModel> getLeads() {
    final jsonList = _prefs.getStringList(AppConstants.storageKeyLeads);
    if (jsonList == null || jsonList.isEmpty) return [];

    try {
      return jsonList
          .map((item) => LeadModel.fromJson(item))
          .toList()
        ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    } catch (_) {
      return [];
    }
  }

  /// Saves the complete list of leads.
  Future<bool> saveLeads(List<LeadModel> leads) async {
    final jsonList = leads.map((l) => l.toJson()).toList();
    return _prefs.setStringList(AppConstants.storageKeyLeads, jsonList);
  }

  /// Inserts or updates a lead.
  Future<bool> upsertLead(LeadModel lead) async {
    final current = getLeads();
    final index = current.indexWhere((l) => l.id == lead.id);

    if (index >= 0) {
      current[index] = lead;
    } else {
      current.insert(0, lead);
    }
    return saveLeads(current);
  }

  /// Deletes a single lead by ID.
  Future<bool> deleteLead(String id) async {
    final current = getLeads();
    current.removeWhere((l) => l.id == id);
    return saveLeads(current);
  }

  /// Clears all stored leads.
  Future<bool> clearAllLeads() async {
    return _prefs.remove(AppConstants.storageKeyLeads);
  }

  // -------------------------------------------------------------
  // SETTINGS & AI API KEY
  // -------------------------------------------------------------

  /// Gets stored Gemini API key.
  String getGeminiApiKey() => _prefs.getString(AppConstants.storageKeyGeminiApiKey) ?? '';

  /// Sets stored Gemini API key.
  Future<bool> setGeminiApiKey(String key) =>
      _prefs.setString(AppConstants.storageKeyGeminiApiKey, key.trim());

  /// Gets whether AI extraction is enabled.
  bool getUseAiExtraction() =>
      _prefs.getBool(AppConstants.storageKeyUseAiExtraction) ?? false;

  /// Sets whether AI extraction is enabled.
  Future<bool> setUseAiExtraction(bool enabled) =>
      _prefs.setBool(AppConstants.storageKeyUseAiExtraction, enabled);

  /// Gets stored Theme Mode (system, light, dark).
  String getThemeMode() =>
      _prefs.getString(AppConstants.storageKeyThemeMode) ?? 'system';

  /// Sets stored Theme Mode.
  Future<bool> setThemeMode(String mode) =>
      _prefs.setString(AppConstants.storageKeyThemeMode, mode);
}
