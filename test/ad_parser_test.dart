import 'package:flutter_test/flutter_test.dart';
import 'package:ad_scanner/models/ad_lead_model.dart';
import 'package:ad_scanner/services/ad_parser_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ad_scanner/services/session_storage_service.dart';

void main() {
  group('AdLeadModel Serialization Tests', () {
    test('Correctly serializes and deserializes JSON and Map', () {
      const model = AdLeadModel(
        companyName: 'FOX Network',
        mailId: 'careers@foxnetwork.com',
        phoneNumber: '210-788-8829',
        contactPersonName: 'Sarah Jenkins',
        address: 'Suite 400, 5th Floor, 742 Evergreen Terrace, Springfield 62704',
      );

      final map = model.toMap();
      final fromMap = AdLeadModel.fromMap(map);
      expect(fromMap, equals(model));

      final jsonString = model.toJson();
      final fromJson = AdLeadModel.fromJson(jsonString);
      expect(fromJson, equals(model));
    });

    test('copyWith updates specified attributes', () {
      const model = AdLeadModel(companyName: 'Acme Corp');
      final updated = model.copyWith(mailId: 'info@acme.com');
      expect(updated.companyName, 'Acme Corp');
      expect(updated.mailId, 'info@acme.com');
      expect(updated.phoneNumber, '');
    });
  });

  group('Multi-Stage AdParserService Precision Tests', () {
    final parser = AdParserService();

    test('Prevents field collision: Slogans rejected, no leaks in address or contact', () {
      final lines = [
        'WE ARE HIRING',
        'DYNAMIC SALES PROFESSIONAL',
        'FOX Network',
        'Requirements: 5+ years experience in Dart & Flutter',
        'Qualifications: BS in Computer Science',
        'Contact: Sarah Jenkins (HR Manager)',
        'Call: 210-788-8829',
        'Send your CV to: hr@foxnetwork.com',
        'Address: Suite 400, 5th Floor, 742 Evergreen Terrace, Springfield 62704',
      ];

      final result = parser.parseLines(lines);

      // Verify exact extraction
      expect(result.companyName, 'FOX Network');
      expect(result.mailId, 'hr@foxnetwork.com');
      expect(result.phoneNumber, '210-788-8829');
      expect(result.contactPersonName, 'Sarah Jenkins');
      expect(result.address, contains('Suite 400'));
      expect(result.address, contains('Springfield 62704'));

      // Verify anti-leak: Phone and email NEVER leak into company, contact, or address
      expect(result.companyName.contains('210-788-8829'), isFalse);
      expect(result.companyName.contains('hr@foxnetwork.com'), isFalse);
      expect(result.contactPersonName.contains('210-788-8829'), isFalse);
      expect(result.contactPersonName.contains('hr@foxnetwork.com'), isFalse);
      expect(result.address.contains('210-788-8829'), isFalse);
      expect(result.address.contains('hr@foxnetwork.com'), isFalse);

      // Verify slogans are NOT company name
      expect(result.companyName.toLowerCase().contains('we are hiring'), isFalse);
      expect(result.companyName.toLowerCase().contains('sales professional'), isFalse);
    });

    test('Parses business advertisement with company suffix & multi-line address', () {
      final lines = [
        'Apex Solutions Ltd',
        'Cloud & AI Engineering',
        'Apply now or reach out to:',
        'Attn: Alex Mercer',
        'Ph: +1 (555) 234-5678',
        'Email: contact@apexsolutions.io',
        'Location: Plot No 45, Cyber Tower, Sector 29',
        'Gurgaon, Haryana 122002',
      ];

      final result = parser.parseLines(lines);

      expect(result.companyName, 'Apex Solutions Ltd');
      expect(result.mailId, 'contact@apexsolutions.io');
      expect(result.phoneNumber, '+1 (555) 234-5678');
      expect(result.contactPersonName, 'Alex Mercer');
      expect(result.address, contains('Plot No 45'));
      expect(result.address, contains('Cyber Tower'));
    });
  });

  group('SessionStorageService Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Saves and loads complete JSON session under cached_ad_lead_session', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = SessionStorageService(prefs);

      const lead = AdLeadModel(
        companyName: 'Vertex Global Corp',
        mailId: 'careers@vertex.com',
        phoneNumber: '800-555-1234',
        contactPersonName: 'David Miller',
        address: '456 Business Blvd, Suite 200, Seattle, WA 98101',
      );

      await storage.saveSession(lead);

      final rehydrated = storage.loadSession();
      expect(rehydrated.companyName, 'Vertex Global Corp');
      expect(rehydrated.mailId, 'careers@vertex.com');
      expect(rehydrated.phoneNumber, '800-555-1234');
      expect(rehydrated.contactPersonName, 'David Miller');
      expect(rehydrated.address, '456 Business Blvd, Suite 200, Seattle, WA 98101');
    });

    test('Clears session cache successfully', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = SessionStorageService(prefs);

      await storage.saveSession(
        const AdLeadModel(
          companyName: 'Test Inc',
          mailId: 'test@test.com',
        ),
      );

      await storage.clearSession();
      final rehydrated = storage.loadSession();
      expect(rehydrated.isEmpty, isTrue);
    });
  });
}
