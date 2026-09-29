/// Application-wide constants including storage keys, routes, and extraction patterns.
class AppConstants {
  // App Branding
  static const String appName = 'Visual Ad Scanner';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Instant OCR & AI Lead Extraction from Visual Ads';

  // SharedPreferences Storage Keys
  static const String storageKeyLeads = 'app_saved_leads_v1';
  static const String storageKeyGeminiApiKey = 'app_gemini_api_key';
  static const String storageKeyUseAiExtraction = 'app_use_ai_extraction';
  static const String storageKeyThemeMode = 'app_theme_mode';
  static const String storageKeyAutoSave = 'app_auto_save_enabled';

  // Navigation Routes
  static const String routeSplash = '/';
  static const String routeHome = '/home';
  static const String routeLeadForm = '/lead-form';
  static const String routeHistory = '/history';
  static const String routeSettings = '/settings';

  // Gemini API URL template
  static const String geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent';

  // Default Regex Patterns
  static final RegExp emailPattern = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
    caseSensitive: false,
  );

  static final RegExp phonePattern = RegExp(
    r'(?:\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}|\b\d{10}\b',
  );

  static final RegExp contactPrefixPattern = RegExp(
    r'\b(contact(?:\s+person)?|hr(?:\s+manager)?|manager|call|send\s+(?:your\s+)?cv\s+to|send\s+resume\s+to|attn|proprietor|prop|founder|owner|director|ceo)\b[:\s-]*',
    caseSensitive: false,
  );

  static final RegExp companyTokensPattern = RegExp(
    r'\b(Network|Solutions|Enterprises|Technologies|Tech|Corp|Corporation|Ltd|LLC|Pvt|Inc|Agency|Studio|Consulting|Group|Holdings|Ventures|Industries|Services)\b',
    caseSensitive: false,
  );

  static final RegExp addressTokensPattern = RegExp(
    r'\b(street|st|avenue|ave|road|rd|floor|tower|building|bldg|opp|opposite|near|suite|ste|plot|cross|layout|pin|zip|postal|lane|block|city|sector|phase|highway)\b',
    caseSensitive: false,
  );

  // Blacklisted promotional phrases
  static const List<String> sloganBlacklist = [
    'we are hiring',
    "we're hiring",
    'we re hiring',
    'hiring now',
    'hiring',
    'wanted',
    'sales representative',
    'job vacancy',
    'urgent vacancy',
    'apply now',
    'requirements',
    'qualifications',
    'responsibilities',
    'send your cv to',
    'join our team',
    'walk in interview',
    'walk-in interview',
    'dynamic sales professional',
    'career opportunity',
    'job alert',
    'urgent requirement',
    'full time',
    'part time',
    'experience required',
  ];
}
