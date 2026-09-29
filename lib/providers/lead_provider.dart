import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/lead_model.dart';
import '../repositories/lead_repository.dart';
import '../services/ocr_service.dart';
import '../services/ad_parser_service.dart';
import '../services/gemini_vision_service.dart';
import '../services/export_service.dart';

enum SortOption { newest, oldest, companyAsc, companyDesc }

/// State management provider for Lead extraction, CRUD, search, filter, and exports.
class LeadProvider extends ChangeNotifier {
  final LeadRepository _repository;
  final OcrService _ocrService;
  final AdParserService _parserService;

  List<LeadModel> _leads = [];
  List<LeadModel> _filteredLeads = [];
  String _searchQuery = '';
  SortOption _sortOption = SortOption.newest;
  bool _filterFavoritesOnly = false;

  bool _isScanning = false;
  String _scanStatusMessage = '';
  File? _lastScannedImage;
  LeadModel? _currentDraftLead;

  LeadProvider({
    required LeadRepository repository,
    OcrService? ocrService,
    AdParserService? parserService,
  })  : _repository = repository,
        _ocrService = ocrService ?? OcrService(),
        _parserService = parserService ?? AdParserService() {
    loadLeads();
  }

  // Getters
  List<LeadModel> get leads => _leads;
  List<LeadModel> get filteredLeads => _filteredLeads;
  List<LeadModel> get recentLeads => _leads.take(5).toList();
  int get totalLeadsCount => _leads.length;
  int get favoritesCount => _leads.where((l) => l.isFavorite).length;
  AdParserService get parserService => _parserService;
  OcrService get ocrService => _ocrService;

  bool get isScanning => _isScanning;
  String get scanStatusMessage => _scanStatusMessage;
  File? get lastScannedImage => _lastScannedImage;
  LeadModel? get currentDraftLead => _currentDraftLead;

  String get searchQuery => _searchQuery;
  SortOption get sortOption => _sortOption;
  bool get filterFavoritesOnly => _filterFavoritesOnly;
  bool get showOnlyFavorites => _filterFavoritesOnly;

  /// Refreshes all leads from the repository and reapplies filters.
  void loadLeads() {
    _leads = _repository.getAllLeads();
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Initiates image acquisition from [source] and executes pure Gemini AI Vision extraction.
  Future<LeadModel?> processAdImage(
    ImageSource source, {
    String? geminiApiKey,
    bool useAi = true,
  }) async {
    _isScanning = true;
    _scanStatusMessage = 'Acquiring advertisement image...';
    notifyListeners();

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 90);

      if (picked == null) {
        _isScanning = false;
        _scanStatusMessage = '';
        notifyListeners();
        return null;
      }

      final imageFile = File(picked.path);
      _lastScannedImage = imageFile;
      _scanStatusMessage = 'Gemini AI Vision analyzing layout & extracting all fields...';
      notifyListeners();

      // Pure Direct Gemini Multimodal Vision Extraction
      final extractedLead = await GeminiVisionService.extractAllDetailsFromImage(
        imageFile,
        explicitApiKey: geminiApiKey,
      );

      _currentDraftLead = extractedLead;
      _isScanning = false;
      _scanStatusMessage = '';
      notifyListeners();

      return extractedLead;
    } catch (e) {
      _isScanning = false;
      _scanStatusMessage = '';
      notifyListeners();
      rethrow;
    }
  }

  /// Sets active draft lead
  void setCurrentDraftLead(LeadModel lead) {
    _currentDraftLead = lead;
    notifyListeners();
  }

  /// Sets last scanned image
  void setLastScannedImage(File? image) {
    _lastScannedImage = image;
    notifyListeners();
  }

  /// Saves or updates a lead into local database.
  Future<bool> saveLead(LeadModel lead) async {
    final success = await _repository.saveLead(lead);
    if (success) {
      loadLeads();
    }
    return success;
  }

  /// Convenience aliases for saveLead
  Future<bool> addLead(LeadModel lead) => saveLead(lead);
  Future<bool> updateLead(LeadModel lead) => saveLead(lead);

  /// Deletes a lead by ID.
  Future<bool> deleteLead(String id) async {
    final success = await _repository.deleteLead(id);
    if (success) {
      loadLeads();
    }
    return success;
  }

  /// Toggles favorite flag on a lead.
  Future<void> toggleFavorite(LeadModel lead) async {
    final updated = lead.copyWith(isFavorite: !lead.isFavorite);
    await saveLead(updated);
  }

  /// Wipes all stored leads.
  Future<bool> clearAllHistory() async {
    final success = await _repository.clearAllLeads();
    if (success) {
      loadLeads();
    }
    return success;
  }

  // -------------------------------------------------------------
  // SEARCH, FILTER & SORT
  // -------------------------------------------------------------

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void toggleFilterFavorites() {
    _filterFavoritesOnly = !_filterFavoritesOnly;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setShowOnlyFavorites(bool value) {
    _filterFavoritesOnly = value;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void _applyFiltersAndSort() {
    List<LeadModel> list = _repository.searchLeads(_searchQuery);

    if (_filterFavoritesOnly) {
      list = list.where((l) => l.isFavorite).toList();
    }

    switch (_sortOption) {
      case SortOption.newest:
        list.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
      case SortOption.oldest:
        list.sort((a, b) => a.scannedAt.compareTo(b.scannedAt));
      case SortOption.companyAsc:
        list.sort((a, b) => a.companyName.toLowerCase().compareTo(b.companyName.toLowerCase()));
      case SortOption.companyDesc:
        list.sort((a, b) => b.companyName.toLowerCase().compareTo(a.companyName.toLowerCase()));
    }

    _filteredLeads = list;
  }

  // -------------------------------------------------------------
  // EXPORTS
  // -------------------------------------------------------------

  Future<void> shareAllAsCsv() async {
    await ExportService.shareCsv(_filteredLeads.isNotEmpty ? _filteredLeads : _leads);
  }

  Future<void> exportLeadsAsCsv() => shareAllAsCsv();

  Future<void> shareSingleLead(LeadModel lead) async {
    await ExportService.shareLead(lead);
  }

  Future<void> copySingleLead(LeadModel lead) async {
    await ExportService.copyToClipboard(lead);
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}
