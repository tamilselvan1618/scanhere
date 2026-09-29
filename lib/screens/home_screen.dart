import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../models/lead_model.dart';
import '../providers/lead_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/custom_button.dart';
import '../widgets/lead_card.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/stat_card.dart';

/// Home Dashboard Screen with futuristic Bento-grid layout, Aurora gradient hero,
/// instant AI scan triggers, and live lead feed.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _handleScan(BuildContext context, ImageSource source) async {
    final leadProvider = context.read<LeadProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    try {
      final lead = await leadProvider.processAdImage(
        source,
        geminiApiKey: settingsProvider.geminiApiKey,
        useAi: settingsProvider.useAiExtraction,
      );

      if (lead != null && context.mounted) {
        Navigator.of(context).pushNamed(
          AppConstants.routeLeadForm,
          arguments: lead,
        );
      }
    } catch (e) {
      if (context.mounted) {
        final err = e.toString().replaceAll('Exception: ', '');
        final userMsg = err.contains('503') || err.contains('UNAVAILABLE')
            ? 'Gemini AI servers are busy right now. Please try again in a moment.'
            : 'Failed to scan image: $err';
        SnackbarHelper.showError(context, userMsg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<LeadProvider>(
      builder: (context, leadProvider, _) {
        return LoadingOverlay(
          isLoading: leadProvider.isScanning,
          message: leadProvider.scanStatusMessage.isNotEmpty
              ? leadProvider.scanStatusMessage
              : 'Extracting lead information...',
          child: Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.accentPurple],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.document_scanner_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Lead History',
                  icon: const Icon(Icons.history_rounded),
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppConstants.routeHistory);
                  },
                ),
                IconButton(
                  tooltip: 'Settings',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppConstants.routeSettings);
                  },
                ),
                const SizedBox(width: 6),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                leadProvider.loadLeads();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Futuristic Hero Banner
                    _buildHeroBanner(context),
                    const SizedBox(height: 18),

                    // 2. Metrics & Stats Bento Row
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Total Scanned',
                            value: '${leadProvider.totalLeadsCount}',
                            icon: Icons.contacts_rounded,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'Starred Leads',
                            value: '${leadProvider.favoritesCount}',
                            icon: Icons.star_rounded,
                            color: AppTheme.accentAmber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // 3. Quick Scan Triggers Header & Bento Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Scan Advertisement',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded, size: 14, color: AppTheme.secondaryColor),
                              SizedBox(width: 4),
                              Text(
                                'AI Powered',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomGradientButton(
                            label: 'Camera Scan',
                            icon: Icons.camera_alt_rounded,
                            gradientColors: const [
                              AppTheme.accentGradientStart,
                              AppTheme.accentGradientMid,
                              AppTheme.accentGradientEnd,
                            ],
                            onPressed: () => _handleScan(context, ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomGradientButton(
                            label: 'Gallery Pick',
                            icon: Icons.photo_library_rounded,
                            gradientColors: const [
                              AppTheme.aiGradientStart,
                              AppTheme.aiGradientMid,
                              AppTheme.aiGradientEnd,
                            ],
                            onPressed: () => _handleScan(context, ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // 4. Recent Scans Feed Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Scans',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (leadProvider.leads.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushNamed(AppConstants.routeHistory);
                            },
                            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                            label: const Text('View All'),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 5. Recent Leads List
                    if (leadProvider.leads.isEmpty)
                      _buildEmptyPlaceholder(context)
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: leadProvider.recentLeads.length,
                        itemBuilder: (context, index) {
                          final lead = leadProvider.recentLeads[index];
                          return LeadCard(
                            lead: lead,
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                AppConstants.routeLeadForm,
                                arguments: lead,
                              );
                            },
                            onDelete: () async {
                              await leadProvider.deleteLead(lead.id);
                              if (context.mounted) {
                                SnackbarHelper.showSuccess(
                                  context,
                                  'Lead deleted successfully.',
                                );
                              }
                            },
                            onToggleFavorite: () {
                              leadProvider.toggleFavorite(lead);
                            },
                            onShare: () {
                              leadProvider.shareSingleLead(lead);
                            },
                            onCopy: () {
                              leadProvider.copySingleLead(lead);
                              SnackbarHelper.showSuccess(
                                context,
                                'Lead details copied to clipboard.',
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  AppConstants.routeLeadForm,
                  arguments: LeadModel.empty(),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Manual Entry',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentGradientStart,
            AppTheme.accentGradientMid,
            AppTheme.accentGradientEnd,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentGradientStart.withValues(alpha: 0.35),
            offset: const Offset(0, 10),
            blurRadius: 22,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Advertisement Scanner',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Precision OCR & Gemini Vision Engine',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Capture flyers, newspaper ads, banners & business cards. Automatically extracts Company, Phone, Email, Contact Person, and Address with >90% precision.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF243048) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.document_scanner_outlined,
              size: 44,
              color: AppTheme.primaryLight,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Leads Scanned Yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap Camera Scan or Gallery Pick above to capture your first ad poster or visiting card.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
