import 'package:flutter_test/flutter_test.dart';
import 'package:ad_scanner/models/ad_lead_model.dart';
import 'package:ad_scanner/models/lead_model.dart';

void main() {
  group('Gemini Vision JSON Schema Deserialization Tests', () {
    test('Correctly deserializes camelCase JSON from Gemini Flash responseSchema', () {
      final jsonSample = {
        'companyName': 'Google DeepMind',
        'mailId': 'careers@deepmind.com',
        'phoneNumber': '+1 650-253-0000',
        'contactPersonName': 'Demis Hassabis',
        'address': '6 Pancras Square, Kings Cross, London N1C 4AG, UK',
      };

      final adLead = AdLeadModel.fromMap(jsonSample);
      expect(adLead.companyName, equals('Google DeepMind'));
      expect(adLead.mailId, equals('careers@deepmind.com'));
      expect(adLead.phoneNumber, equals('+1 650-253-0000'));
      expect(adLead.contactPersonName, equals('Demis Hassabis'));
      expect(adLead.address, equals('6 Pancras Square, Kings Cross, London N1C 4AG, UK'));

      final domainLead = LeadModel.fromMap(jsonSample);
      expect(domainLead.companyName, equals('Google DeepMind'));
      expect(domainLead.mailId, equals('careers@deepmind.com'));
      expect(domainLead.phoneNumber, equals('+1 650-253-0000'));
      expect(domainLead.contactPersonName, equals('Demis Hassabis'));
      expect(domainLead.address, equals('6 Pancras Square, Kings Cross, London N1C 4AG, UK'));
    });

    test('Correctly handles snake_case JSON gracefully', () {
      final jsonSample = {
        'company_name': 'Vertex AI Solutions',
        'mail_id': 'support@vertex.ai',
        'phone_number': '1-800-VERTEX',
        'contact_person_name': 'Alice Zhang',
        'address': 'Mountain View, CA 94043',
      };

      final adLead = AdLeadModel.fromMap(jsonSample);
      expect(adLead.companyName, equals('Vertex AI Solutions'));
      expect(adLead.mailId, equals('support@vertex.ai'));
      expect(adLead.phoneNumber, equals('1-800-VERTEX'));
      expect(adLead.contactPersonName, equals('Alice Zhang'));
      expect(adLead.address, equals('Mountain View, CA 94043'));
    });
  });
}
