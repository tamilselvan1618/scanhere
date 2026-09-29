import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/lead_model.dart';
import '../utils/formatters.dart';

/// Service managing export of leads to CSV, formatted text summaries, and sharing.
class ExportService {
  /// Generates RFC 4180-compliant CSV content from a list of leads.
  static String generateCsv(List<LeadModel> leads) {
    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln('ID,Company Name,Email,Phone Number,Contact Person,Address,Notes,Scanned Date');

    for (final lead in leads) {
      final row = [
        _escapeCsv(lead.id),
        _escapeCsv(lead.companyName),
        _escapeCsv(lead.mailId),
        _escapeCsv(lead.phoneNumber),
        _escapeCsv(lead.contactPersonName),
        _escapeCsv(lead.address),
        _escapeCsv(lead.notes),
        _escapeCsv(AppFormatters.formatDateTime(lead.scannedAt)),
      ];
      buffer.writeln(row.join(','));
    }
    return buffer.toString();
  }

  /// Formats a single lead into a readable text summary.
  static String formatLeadAsText(LeadModel lead) {
    final buffer = StringBuffer();
    buffer.writeln('📋 LEAD DETAILS:');
    if (lead.companyName.isNotEmpty) buffer.writeln('🏢 Company: ${lead.companyName}');
    if (lead.contactPersonName.isNotEmpty) buffer.writeln('👤 Contact: ${lead.contactPersonName}');
    if (lead.phoneNumber.isNotEmpty) buffer.writeln('📞 Phone: ${lead.phoneNumber}');
    if (lead.mailId.isNotEmpty) buffer.writeln('✉️ Email: ${lead.mailId}');
    if (lead.address.isNotEmpty) buffer.writeln('📍 Address: ${lead.address}');
    if (lead.extraFields.isNotEmpty) {
      lead.extraFields.forEach((k, v) {
        buffer.writeln('🔹 $k: $v');
      });
    }
    if (lead.notes.isNotEmpty) buffer.writeln('📝 Notes: ${lead.notes}');
    buffer.writeln('📅 Scanned: ${Formatters.formatDateTime(lead.scannedAt)}');
    return buffer.toString();
  }

  /// Copies lead text summary to clipboard.
  static Future<void> copyToClipboard(LeadModel lead) async {
    final text = formatLeadAsText(lead);
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Shares a single lead via system share sheet.
  static Future<void> shareLead(LeadModel lead) async {
    final text = formatLeadAsText(lead);
    await Share.share(text, subject: 'Business Lead: ${lead.companyName}');
  }

  /// Shares exported CSV data via system share sheet.
  static Future<void> shareCsv(List<LeadModel> leads) async {
    final csvContent = generateCsv(leads);
    await Share.share(
      csvContent,
      subject: 'Exported Leads (${leads.length}) - CSV',
    );
  }

  static String _escapeCsv(String field) {
    final clean = field.replaceAll('"', '""');
    if (clean.contains(',') || clean.contains('\n') || clean.contains('"')) {
      return '"$clean"';
    }
    return clean;
  }
}
