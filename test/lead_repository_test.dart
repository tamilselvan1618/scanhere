import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ad_scanner/models/lead_model.dart';
import 'package:ad_scanner/repositories/lead_repository.dart';
import 'package:ad_scanner/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late LeadRepository leadRepository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = StorageService(prefs);
    leadRepository = LeadRepositoryImpl(storageService);
  });

  group('LeadRepository & StorageService CRUD Tests', () {
    test('Saves, retrieves, and updates leads in storage', () async {
      final lead1 = LeadModel(
        companyName: 'TechCorp Solutions',
        mailId: 'jobs@techcorp.com',
        phoneNumber: '555-0100',
      );

      final saveSuccess = await leadRepository.saveLead(lead1);
      expect(saveSuccess, isTrue);

      final allLeads = leadRepository.getAllLeads();
      expect(allLeads.length, equals(1));
      expect(allLeads.first.companyName, equals('TechCorp Solutions'));

      // Update lead
      final updated = lead1.copyWith(isFavorite: true);
      await leadRepository.saveLead(updated);

      final reloaded = leadRepository.getLeadById(lead1.id);
      expect(reloaded, isNotNull);
      expect(reloaded!.isFavorite, isTrue);
    });

    test('Searches leads by company, phone, email, or contact name', () async {
      final lead1 = LeadModel(
        companyName: 'Alpha Networks',
        mailId: 'alpha@mail.com',
        phoneNumber: '111-222-3333',
        contactPersonName: 'Alice Smith',
      );
      final lead2 = LeadModel(
        companyName: 'Beta Dynamics',
        mailId: 'beta@mail.com',
        phoneNumber: '444-555-6666',
        contactPersonName: 'Bob Jones',
      );

      await leadRepository.saveLead(lead1);
      await leadRepository.saveLead(lead2);

      expect(leadRepository.searchLeads('Alpha').length, equals(1));
      expect(leadRepository.searchLeads('Jones').length, equals(1));
      expect(leadRepository.searchLeads('444').length, equals(1));
      expect(leadRepository.searchLeads('nonexistent').isEmpty, isTrue);
    });

    test('Deletes a single lead and clears all history', () async {
      final lead1 = LeadModel(companyName: 'Lead 1');
      final lead2 = LeadModel(companyName: 'Lead 2');

      await leadRepository.saveLead(lead1);
      await leadRepository.saveLead(lead2);
      expect(leadRepository.getAllLeads().length, equals(2));

      await leadRepository.deleteLead(lead1.id);
      expect(leadRepository.getAllLeads().length, equals(1));
      expect(leadRepository.getAllLeads().first.id, equals(lead2.id));

      await leadRepository.clearAllLeads();
      expect(leadRepository.getAllLeads().isEmpty, isTrue);
    });
  });
}
