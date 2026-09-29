import 'package:shared_preferences/shared_preferences.dart';
import '../models/ad_lead_model.dart';

/// Service responsible for local persistence and rehydration of extracted ad lead sessions.
class SessionStorageService {
  static const String sessionKey = 'cached_ad_lead_session';

  final SharedPreferences _prefs;

  SessionStorageService(this._prefs);

  /// Initializes the service with the platform SharedPreferences instance.
  static Future<SessionStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SessionStorageService(prefs);
  }

  /// Loads the persisted lead session, returning an empty [AdLeadModel] if none exists.
  AdLeadModel loadSession() {
    final jsonString = _prefs.getString(sessionKey);
    if (jsonString != null && jsonString.trim().isNotEmpty) {
      try {
        return AdLeadModel.fromJson(jsonString);
      } catch (_) {
        return const AdLeadModel();
      }
    }
    return const AdLeadModel();
  }

  /// Saves the complete [AdLeadModel] to storage as a JSON string.
  Future<bool> saveSession(AdLeadModel model) async {
    return _prefs.setString(sessionKey, model.toJson());
  }

  /// Alias for saveSession
  Future<bool> saveLeadSession(AdLeadModel model) => saveSession(model);

  /// Alias for loadSession
  Future<AdLeadModel?> restoreLeadSession() async => loadSession();

  /// Saves individual field values into storage as an [AdLeadModel] JSON.
  Future<bool> saveFields({
    required String companyName,
    required String mailId,
    required String phoneNumber,
    required String contactPersonName,
    required String address,
  }) async {
    return saveSession(
      AdLeadModel(
        companyName: companyName,
        mailId: mailId,
        phoneNumber: phoneNumber,
        contactPersonName: contactPersonName,
        address: address,
      ),
    );
  }

  /// Clears the cached session from local storage.
  Future<bool> clearSession() async {
    return _prefs.remove(sessionKey);
  }
}
