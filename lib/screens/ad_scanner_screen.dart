import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ad_lead_model.dart';
import '../services/ad_parser_service.dart';
import '../services/gemini_vision_service.dart';
import '../services/ocr_service.dart';
import '../services/session_storage_service.dart';

/// Screen responsible for acquiring advertisement media, performing direct Gemini Vision or
/// on-device OCR inference, parsing 5 core attributes, and managing an editable form backed by local persistence.
class AdScannerScreen extends StatefulWidget {
  const AdScannerScreen({super.key});

  @override
  State<AdScannerScreen> createState() => _AdScannerScreenState();
}

class _AdScannerScreenState extends State<AdScannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final OcrService _ocrService;
  late final AdParserService _adParserService;
  SessionStorageService? _sessionStorage;

  // 5 Form Controllers
  final _companyController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isInitializing = true;
  bool _isProcessing = false;
  bool _useGeminiVision = true;
  File? _scannedImageFile;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _ocrService = OcrService();
    _adParserService = AdParserService();
    _rehydrateSavedSession();
  }

  /// Restores session state from SharedPreferences on initial launch
  Future<void> _rehydrateSavedSession() async {
    try {
      final session = await SessionStorageService.init();
      _sessionStorage = session;
      final savedData = session.loadSession();

      if (mounted) {
        setState(() {
          _populateFields(savedData);
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitializing = false);
        _showSnackBar('Failed to load previous session: $e', isError: true);
      }
    }
  }

  void _populateFields(AdLeadModel lead) {
    _companyController.text = lead.companyName;
    _emailController.text = lead.mailId;
    _phoneController.text = lead.phoneNumber;
    _contactPersonController.text = lead.contactPersonName;
    _addressController.text = lead.address;
  }

  /// Automatically caches the current form state to SharedPreferences
  Future<void> _persistCurrentState() async {
    if (_sessionStorage == null) return;
    await _sessionStorage!.saveFields(
      companyName: _companyController.text,
      mailId: _emailController.text,
      phoneNumber: _phoneController.text,
      contactPersonName: _contactPersonController.text,
      address: _addressController.text,
    );
  }

  /// Captures image from Camera or Gallery and triggers the extraction pipeline
  Future<void> _handleImageScan(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    final imageFile = File(pickedFile.path);

    setState(() {
      _isProcessing = true;
      _scannedImageFile = imageFile;
      _statusMessage = _useGeminiVision
          ? 'Gemini Flash is analyzing the flyer layout...'
          : 'Running OCR & parsing attributes...';
    });

    try {
      AdLeadModel extractedLead;

      if (_useGeminiVision) {
        try {
          // Direct multimodal visual reasoning with Gemini Flash
          extractedLead = await GeminiVisionService.extractLeadDirectlyFromImage(
            imageFile,
          );
        } catch (visionError) {
          // Fallback to offline OCR pipeline if network/API fails
          if (mounted) {
            _showSnackBar(
              'Gemini Vision failed ($visionError). Falling back to offline OCR...',
              isWarning: true,
            );
          }
          final ocrResult = await _ocrService.recognizeFile(imageFile);
          extractedLead = _adParserService.parseRecognizedText(ocrResult);
        }
      } else {
        // Pure offline ML Kit OCR
        final ocrResult = await _ocrService.recognizeFile(imageFile);
        extractedLead = _adParserService.parseRecognizedText(ocrResult);
      }

      if (!mounted) return;

      setState(() {
        _populateFields(extractedLead);
        _isProcessing = false;
        _statusMessage = null;
      });

      await _persistCurrentState();

      if (extractedLead.isEmpty) {
        _showSnackBar(
          'Scanning finished, but no distinct attributes were identified. Please enter details manually.',
          isWarning: true,
        );
      } else {
        _showSnackBar(
          _useGeminiVision
              ? 'Lead extracted via Gemini Vision!'
              : 'Ad scanned via Offline OCR!',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusMessage = null;
      });
      _showSnackBar('Error during scan processing: $e', isError: true);
    }
  }

  /// Clears form state and wipes local session
  Future<void> _handleClearSession() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Clear Session & Form?'),
            ],
          ),
          content: const Text(
            'This action will wipe all persisted session data and reset all 5 form fields.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _sessionStorage?.clearSession();
      setState(() {
        _companyController.clear();
        _emailController.clear();
        _phoneController.clear();
        _contactPersonController.clear();
        _addressController.clear();
        _scannedImageFile = null;
      });
      _showSnackBar('Session and form cleared successfully.');
    }
  }

  /// Validates and submits the lead
  void _handleSubmitLead() {
    final company = _companyController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final contactPerson = _contactPersonController.text.trim();
    final address = _addressController.text.trim();

    if (company.isEmpty && phone.isEmpty && email.isEmpty) {
      _showSnackBar(
        'Validation Error: Please provide at least a Company Name, Phone Number, or Email.',
        isError: true,
      );
      return;
    }

    final lead = AdLeadModel(
      companyName: company,
      mailId: email,
      phoneNumber: phone,
      contactPersonName: contactPerson,
      address: address,
    );

    _sessionStorage?.saveLeadSession(lead);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Lead Verified & Saved'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lead saved for "${lead.companyName.isNotEmpty ? lead.companyName : "Unnamed Lead"}":',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 14),
              _buildSummaryRow('Company:', company.isEmpty ? 'N/A' : company),
              _buildSummaryRow('Email:', email.isEmpty ? 'N/A' : email),
              _buildSummaryRow('Phone:', phone.isEmpty ? 'N/A' : phone),
              _buildSummaryRow('Contact:', contactPerson.isEmpty ? 'N/A' : contactPerson),
              _buildSummaryRow('Address:', address.isEmpty ? 'N/A' : address),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false, bool isWarning = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    Color backgroundColor = Theme.of(context).colorScheme.primary;
    IconData icon = Icons.info_outline;

    if (isError) {
      backgroundColor = Theme.of(context).colorScheme.error;
      icon = Icons.error_outline;
    } else if (isWarning) {
      backgroundColor = Colors.orange.shade800;
      icon = Icons.warning_amber_rounded;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  void dispose() {
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _contactPersonController.dispose();
    _addressController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gemini Visual Lead Scanner',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'Clear Session & Form',
            icon: const Icon(Icons.delete_outline),
            onPressed: _handleClearSession,
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mode Toggle Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _useGeminiVision
                                ? Icons.auto_awesome_rounded
                                : Icons.document_scanner_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _useGeminiVision
                                  ? 'Gemini Flash Multimodal Vision (Zero OCR)'
                                  : 'Offline Google ML Kit OCR Engine',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Switch(
                            value: _useGeminiVision,
                            onChanged: (val) => setState(() => _useGeminiVision = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Camera / Gallery Action Bar
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Scan Flyer'),
                            onPressed: _isProcessing
                                ? null
                                : () => _handleImageScan(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Pick Image'),
                            onPressed: _isProcessing
                                ? null
                                : () => _handleImageScan(ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),

                    // Scanned Image Thumbnail
                    if (_scannedImageFile != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(alpha: 0.3),
                          ),
                          image: DecorationImage(
                            image: FileImage(_scannedImageFile!),
                            fit: BoxFit.cover,
                          ),
                        ),
                        alignment: Alignment.bottomRight,
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Active Ad Poster',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    Text(
                      'Editable Lead Attributes',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 1. Company Name
                    TextFormField(
                      controller: _companyController,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _persistCurrentState(),
                      decoration: const InputDecoration(
                        labelText: 'Company / Organization Name *',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Company name is required'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // 2. Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _persistCurrentState(),
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 3. Phone Number
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _persistCurrentState(),
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4. Contact Person
                    TextFormField(
                      controller: _contactPersonController,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _persistCurrentState(),
                      decoration: const InputDecoration(
                        labelText: 'Contact Person Name / HR',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 5. Address
                    TextFormField(
                      controller: _addressController,
                      keyboardType: TextInputType.multiline,
                      minLines: 2,
                      maxLines: 4,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => _persistCurrentState(),
                      decoration: const InputDecoration(
                        labelText: 'Location / Address',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _handleSubmitLead,
                      child: const Text(
                        'Save / Submit Lead',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Loading Overlay
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          _statusMessage ?? 'Analyzing flyer...',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
