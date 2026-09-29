import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../providers/lead_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/snackbar_helper.dart';

/// Clean Settings screen for theme selection, database management, and app information.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _confirmClearDatabase(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Clear All Lead History?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'This action will permanently wipe all scanned leads from local storage. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final provider = context.read<LeadProvider>();
              final success = await provider.clearAllHistory();
              if (context.mounted) {
                if (success) {
                  SnackbarHelper.showSuccess(context, 'Database cleared successfully.');
                } else {
                  SnackbarHelper.showError(context, 'Failed to clear database.');
                }
              }
            },
            child: const Text('Wipe Everything'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // 1. Theme Configuration Bento Card
              _buildSectionHeader('Appearance & Theme'),
              _buildBentoCard(
                context,
                isDark: isDark,
                child: Column(
                  children: [
                    _buildThemeTile(
                      context,
                      title: 'System Default',
                      subtitle: 'Adapts to system dark/light mode',
                      icon: Icons.settings_suggest_rounded,
                      mode: ThemeMode.system,
                      currentMode: settings.themeMode,
                      onSelect: settings.setThemeMode,
                      isDark: isDark,
                    ),
                    Divider(
                      height: 1,
                      color: isDark ? const Color(0xFF243048) : const Color(0xFFE2E8F0),
                    ),
                    _buildThemeTile(
                      context,
                      title: 'Light Mode',
                      subtitle: 'Clean pearlescent daylight theme',
                      icon: Icons.light_mode_rounded,
                      mode: ThemeMode.light,
                      currentMode: settings.themeMode,
                      onSelect: settings.setThemeMode,
                      isDark: isDark,
                    ),
                    Divider(
                      height: 1,
                      color: isDark ? const Color(0xFF243048) : const Color(0xFFE2E8F0),
                    ),
                    _buildThemeTile(
                      context,
                      title: 'Obsidian Dark Mode',
                      subtitle: 'Deep futuristic OLED dark theme',
                      icon: Icons.dark_mode_rounded,
                      mode: ThemeMode.dark,
                      currentMode: settings.themeMode,
                      onSelect: settings.setThemeMode,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 2. Storage & Data Management Bento Card
              _buildSectionHeader('Storage & Data'),
              _buildBentoCard(
                context,
                isDark: isDark,
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.delete_forever_rounded,
                          color: Color(0xFFEF4444),
                          size: 22,
                        ),
                      ),
                      title: const Text(
                        'Wipe Local Database',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Erase all saved lead records from local device storage',
                        style: TextStyle(fontSize: 12.5),
                      ),
                      onTap: () => _confirmClearDatabase(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 3. About App Info Bento Card
              _buildSectionHeader('About Application'),
              _buildBentoCard(
                context,
                isDark: isDark,
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryColor, AppTheme.accentPurple],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.document_scanner_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      title: const Text(
                        AppConstants.appName,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Version 1.0.0 • Pure Gemini AI Multimodal Vision',
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildBentoCard(
    BuildContext context, {
    required Widget child,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF243048) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: child,
    );
  }

  Widget _buildThemeTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required ValueChanged<ThemeMode> onSelect,
    required bool isDark,
  }) {
    final isSelected = mode == currentMode;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: isDark ? 0.25 : 0.12)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? AppTheme.primaryColor
              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          color: isSelected ? AppTheme.primaryColor : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
      trailing: isSelected
          ? const Icon(
              Icons.check_circle_rounded,
              color: AppTheme.primaryColor,
              size: 22,
            )
          : null,
      onTap: () => onSelect(mode),
    );
  }
}
