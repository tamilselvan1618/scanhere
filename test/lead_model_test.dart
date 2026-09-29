import 'package:flutter_test/flutter_test.dart';
import 'package:ad_scanner/models/lead_model.dart';

void main() {
  group('LeadModel Tests', () {
    test('Correctly serializes and deserializes JSON and Map', () {
      final lead = LeadModel(
        companyName: 'Apex Innovations LLC',
        mailId: 'careers@apex.com',
        phoneNumber: '+1 800-555-0199',
        contactPersonName: 'Sarah Jenkins',
        address: '100 Silicon Way, Tech Park, CA',
        notes: 'Urgent hiring for Mobile Lead',
        isFavorite: true,
      );

      final map = lead.toMap();
      expect(map['company_name'], equals('Apex Innovations LLC'));
      expect(map['mail_id'], equals('careers@apex.com'));
      expect(map['phone_number'], equals('+1 800-555-0199'));
      expect(map['contact_person_name'], equals('Sarah Jenkins'));
      expect(map['is_favorite'], isTrue);

      final jsonStr = lead.toJson();
      final restored = LeadModel.fromJson(jsonStr);

      expect(restored.companyName, equals(lead.companyName));
      expect(restored.mailId, equals(lead.mailId));
      expect(restored.phoneNumber, equals(lead.phoneNumber));
      expect(restored.contactPersonName, equals(lead.contactPersonName));
      expect(restored.address, equals(lead.address));
      expect(restored.isFavorite, isTrue);
    });

    test('isEmpty and isNotEmpty helpers work accurately', () {
      final emptyLead = LeadModel.empty();
      expect(emptyLead.isEmpty, isTrue);
      expect(emptyLead.isNotEmpty, isFalse);

      final populatedLead = LeadModel(companyName: 'Nexus Tech');
      expect(populatedLead.isEmpty, isFalse);
      expect(populatedLead.isNotEmpty, isTrue);
    });

    test('copyWith updates specified fields only', () {
      final original = LeadModel(
        companyName: 'Original Corp',
        mailId: 'info@orig.com',
        isFavorite: false,
      );

      final updated = original.copyWith(
        companyName: 'Updated Corp',
        isFavorite: true,
      );

      expect(updated.id, equals(original.id));
      expect(updated.companyName, equals('Updated Corp'));
      expect(updated.mailId, equals('info@orig.com'));
      expect(updated.isFavorite, isTrue);
    });
  });
}
