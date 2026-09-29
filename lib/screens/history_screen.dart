import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../providers/lead_provider.dart';
import '../theme/app_theme.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/lead_card.dart';

/// Screen displaying all scanned leads with frosted search bar, filter chips,
/// sort modal, and CSV batch export.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSortDialog(BuildContext context, LeadProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: Text(
                  'Sort Leads By',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const Divider(),
              _buildSortOptionTile(
                context,
                title: 'Date Scanned (Newest First)',
                option: SortOption.newest,
                provider: provider,
              ),
              _buildSortOptionTile(
                context,
                title: 'Date Scanned (Oldest First)',
                option: SortOption.oldest,
                provider: provider,
              ),
              _buildSortOptionTile(
                context,
                title: 'Company Name (A to Z)',
                option: SortOption.companyAsc,
                provider: provider,
              ),
              _buildSortOptionTile(
                context,
                title: 'Company Name (Z to A)',
                option: SortOption.companyDesc,
                provider: provider,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortOptionTile(
    BuildContext context, {
    required String title,
    required SortOption option,
    required LeadProvider provider,
  }) {
    final isSelected = provider.sortOption == option;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          color: isSelected ? AppTheme.primaryColor : null,
        ),
      ),
      leading: Icon(
        isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
        color: isSelected ? AppTheme.primaryColor : Colors.grey,
      ),
      onTap: () {
        provider.setSortOption(option);
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<LeadProvider>(
      builder: (context, leadProvider, _) {
        final leads = leadProvider.filteredLeads;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Scanned Leads'),
            actions: [
              IconButton(
                tooltip: 'Sort Leads',
                icon: const Icon(Icons.sort_rounded),
                onPressed: () => _showSortDialog(context, leadProvider),
              ),
              IconButton(
                tooltip: 'Export CSV',
                icon: const Icon(Icons.file_download_outlined),
                onPressed: () async {
                  if (leads.isEmpty) {
                    SnackbarHelper.showError(context, 'No leads available to export.');
                    return;
                  }
                  await leadProvider.exportLeadsAsCsv();
                  if (context.mounted) {
                    SnackbarHelper.showSuccess(context, 'Export file ready.');
                  }
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: Column(
            children: [
              // 1. Search Bar & Filter Chips Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search company, phone, email, contact...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 22),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  leadProvider.setSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (query) {
                        leadProvider.setSearchQuery(query);
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),

                    // Filter Chips Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'All (${leadProvider.totalLeadsCount})',
                            isSelected: !leadProvider.showOnlyFavorites,
                            onSelected: () => leadProvider.setShowOnlyFavorites(false),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Starred (${leadProvider.favoritesCount})',
                            isSelected: leadProvider.showOnlyFavorites,
                            icon: Icons.star_rounded,
                            activeColor: const Color(0xFFF59E0B),
                            onSelected: () => leadProvider.setShowOnlyFavorites(true),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Leads List
              Expanded(
                child: leads.isEmpty
                    ? _buildEmptySearchPlaceholder(context, leadProvider)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        itemCount: leads.length,
                        itemBuilder: (context, index) {
                          final lead = leads[index];
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
                                  'Lead removed from history.',
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
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required bool isDark,
    IconData? icon,
    Color? activeColor,
  }) {
    final color = activeColor ?? AppTheme.primaryColor;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? const Color(0xFF131B2E) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? const Color(0xFF243048) : const Color(0xFFCBD5E1)),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchPlaceholder(BuildContext context, LeadProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              provider.searchQuery.isNotEmpty
                  ? 'No matching leads found'
                  : (provider.showOnlyFavorites
                      ? 'No starred leads yet'
                      : 'No leads in history'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.searchQuery.isNotEmpty
                  ? 'Try searching with a different name, phone number, or email.'
                  : 'Start scanning advertisement flyers and cards from the Home screen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
