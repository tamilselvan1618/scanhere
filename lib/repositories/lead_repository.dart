import '../models/lead_model.dart';
import '../services/storage_service.dart';

/// Contract definition for Lead Data Repository.
abstract class LeadRepository {
  List<LeadModel> getAllLeads();
  LeadModel? getLeadById(String id);
  Future<bool> saveLead(LeadModel lead);
  Future<bool> deleteLead(String id);
  Future<bool> clearAllLeads();
  List<LeadModel> searchLeads(String query);
}

/// Implementation of [LeadRepository] backed by local [StorageService].
class LeadRepositoryImpl implements LeadRepository {
  final StorageService _storageService;

  LeadRepositoryImpl(this._storageService);

  @override
  List<LeadModel> getAllLeads() {
    return _storageService.getLeads();
  }

  @override
  LeadModel? getLeadById(String id) {
    try {
      return getAllLeads().firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> saveLead(LeadModel lead) {
    return _storageService.upsertLead(lead);
  }

  @override
  Future<bool> deleteLead(String id) {
    return _storageService.deleteLead(id);
  }

  @override
  Future<bool> clearAllLeads() {
    return _storageService.clearAllLeads();
  }

  @override
  List<LeadModel> searchLeads(String query) {
    final lower = query.trim().toLowerCase();
    if (lower.isEmpty) return getAllLeads();

    return getAllLeads().where((l) {
      return l.companyName.toLowerCase().contains(lower) ||
          l.phoneNumber.toLowerCase().contains(lower) ||
          l.mailId.toLowerCase().contains(lower) ||
          l.contactPersonName.toLowerCase().contains(lower) ||
          l.address.toLowerCase().contains(lower) ||
          l.notes.toLowerCase().contains(lower);
    }).toList();
  }
}
