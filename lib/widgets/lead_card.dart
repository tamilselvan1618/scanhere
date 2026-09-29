import 'package:flutter/material.dart';
import '../models/lead_model.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Bento-styled Lead Card rendering all lead attributes with modern actions and tags.
class LeadCard extends StatelessWidget {
  final LeadModel lead;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onShare;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;

  const LeadCard({
    super.key,
    required this.lead,
    this.onTap,
    this.onFavoriteToggle,
    this.onToggleFavorite,
    this.onShare,
    this.onCopy,
    this.onDelete,
  });

  Color _getAvatarColor(String name) {
    if (name.isEmpty) return AppTheme.primaryColor;
    final hash = name.codeUnits.fold<int>(0, (prev, elem) => prev + elem);
    const colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.accentPurple,
      AppTheme.accentPink,
      AppTheme.accentEmerald,
    ];
    return colors[hash % colors.length];
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'AD';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final favoriteAction = onToggleFavorite ?? onFavoriteToggle;
    final avatarColor = _getAvatarColor(lead.companyName);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF243048) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row: Monogram Avatar + Title + Favorite Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            avatarColor,
                            avatarColor.withValues(alpha: 0.75),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: avatarColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _getInitials(lead.companyName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lead.companyName.isNotEmpty
                               ? lead.companyName
                                : 'Unnamed Ad Lead',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          if (lead.contactPersonName.isNotEmpty)
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_rounded,
                                  size: 14,
                                  color: AppTheme.primaryLight,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    lead.contactPersonName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF475569),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    if (favoriteAction != null)
                      IconButton(
                        icon: Icon(
                          lead.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: lead.isFavorite
                              ? const Color(0xFFF59E0B)
                              : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                          size: 24,
                        ),
                        onPressed: favoriteAction,
                        tooltip: lead.isFavorite ? 'Remove Star' : 'Star Lead',
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Contact info pills / rows
                if (lead.phoneNumber.isNotEmpty || lead.mailId.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        if (lead.phoneNumber.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.phone_outlined,
                                  size: 15,
                                  color: AppTheme.secondaryColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    Formatters.formatPhoneNumber(lead.phoneNumber),
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (lead.phoneNumber.isNotEmpty && lead.mailId.isNotEmpty)
                          Divider(
                            height: 12,
                            thickness: 0.8,
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          ),
                        if (lead.mailId.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.mail_outline_rounded,
                                  size: 15,
                                  color: AppTheme.accentPink,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    lead.mailId,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? const Color(0xFFCBD5E1)
                                          : const Color(0xFF334155),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                // Physical Address
                if (lead.address.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          lead.address,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // Dynamic Extra Fields Chips
                if (lead.extraFields.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: lead.extraFields.entries.take(4).map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.3 : 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${entry.key}: ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                              ),
                            ),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 130),
                              child: Text(
                                entry.value,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 12),

                // Footer Row: Date Scanned + Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Formatters.formatDateTime(lead.scannedAt),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onCopy != null)
                          _buildActionIconButton(
                            context,
                            icon: Icons.copy_rounded,
                            tooltip: 'Copy Lead',
                            onPressed: onCopy!,
                          ),
                        if (onShare != null)
                          _buildActionIconButton(
                            context,
                            icon: Icons.share_rounded,
                            tooltip: 'Share Lead',
                            onPressed: onShare!,
                          ),
                        if (onDelete != null)
                          _buildActionIconButton(
                            context,
                            icon: Icons.delete_outline_rounded,
                            tooltip: 'Delete Lead',
                            color: const Color(0xFFEF4444),
                            onPressed: onDelete!,
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionIconButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(7.0),
            child: Icon(
              icon,
              size: 16,
              color: color ?? (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
            ),
          ),
        ),
      ),
    );
  }
}
