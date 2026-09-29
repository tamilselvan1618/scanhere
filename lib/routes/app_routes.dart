import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../models/lead_model.dart';
import '../screens/history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/lead_form_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/splash_screen.dart';

/// Centralized route generator and named route registry.
class AppRoutes {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppConstants.routeSplash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      case AppConstants.routeHome:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );

      case AppConstants.routeLeadForm:
        final lead = settings.arguments as LeadModel?;
        return MaterialPageRoute(
          builder: (_) => LeadFormScreen(initialLead: lead),
          settings: settings,
        );

      case AppConstants.routeHistory:
        return MaterialPageRoute(
          builder: (_) => const HistoryScreen(),
          settings: settings,
        );

      case AppConstants.routeSettings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Route not found'),
            ),
          ),
        );
    }
  }
}
