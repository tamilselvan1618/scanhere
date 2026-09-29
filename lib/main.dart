import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'providers/lead_provider.dart';
import 'providers/settings_provider.dart';
import 'repositories/lead_repository.dart';
import 'routes/app_routes.dart';
import 'services/ad_parser_service.dart';
import 'services/ocr_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // Graceful fallback if .env is absent in some build targets
  }

  // Set system UI preferences
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize persistent Local Storage
  final sharedPreferences = await SharedPreferences.getInstance();
  final storageService = StorageService(sharedPreferences);

  // Initialize Core Services and Repositories
  final leadRepository = LeadRepositoryImpl(storageService);
  final ocrService = OcrService();
  final parserService = AdParserService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(storageService),
        ),
        ChangeNotifierProvider<LeadProvider>(
          create: (_) => LeadProvider(
            repository: leadRepository,
            ocrService: ocrService,
            parserService: parserService,
          ),
        ),
      ],
      child: const VisualAdScannerApp(),
    ),
  );
}

/// Root Application Widget with Material 3 theming, routing, and dynamic theme switching.
class VisualAdScannerApp extends StatelessWidget {
  const VisualAdScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          initialRoute: AppConstants.routeSplash,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        );
      },
    );
  }
}
