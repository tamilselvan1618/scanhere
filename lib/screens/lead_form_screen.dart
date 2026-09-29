import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/lead_model.dart';
import '../providers/lead_provider.dart';
import '../providers/settings_provider.dart';
import '../services/gemini_vision_service.dart';
import '../theme/app_theme.dart';
import '../utils/snackbar_helper.dart';
import '../utils/validators.dart';
import '../widgets/custom_button.dart';

/// Form Screen for reviewing, editing, validating, dynamic custom field management,
/// and Gemini AI all-detail extraction.
class LeadFormScreen extends StatefulWidget {
  final LeadModel? initialLead;

  const LeadFormScreen({super.key, this.initialLead});

  @override
  State<LeadFormScreen> createState() => _LeadFormScreenState();
}

class _LeadFormScreenState extends State<LeadFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late TextEditingController _companyController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _contactPersonController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;

  // Dynamic extra key-value controllers list
  final List<({TextEditingController key, TextEditingController value})>
      _dynamicFieldControllers = [];

  String? _imagePath;
  DateTime _scannedAt = DateTime.now();
  String _leadId = '';
  bool _isFavorite = false;
  bool _isSaving = false;
  bool _isExtractingWithAi = false;

  @override
  void initState() {
    super.initState();
    final lead = widget.initialLead ?? LeadModel.empty();

    _leadId = lead.id;
    _companyController = TextEditingController(text: lead.companyName);
    _emailController = TextEditingController(text: lead.mailId);
    _phoneController = TextEditingController(text: lead.phoneNumber);
    _contactPersonController = TextEditingController(text: lead.contactPersonName);
    _addressController = TextEditingController(text: lead.address);
    _notesController = TextEditingController(text: lead.notes);
    _imagePath = lead.imagePath;
    _scannedAt = lead.scannedAt;
    _isFavorite = lead.isFavorite;

    // Initialize existing extra dynamic fields
    lead.extraFields.forEach((k, v) {
      _dynamicFieldControllers.add((
        key: TextEditingController(text: k),
        value: TextEditingController(text: v),
      ));
    });
  }

  @override
  void dispose() {
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _contactPersonController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    for (final pair in _dynamicFieldControllers) {
      pair.key.dispose();
      pair.value.dispose();
    }
    super.dispose();
  }

  void _addCustomField({String key = '', String value = ''}) {
    setState(() {
      _dynamicFieldControllers.add((
        key: TextEditingController(text: key),
        value: TextEditingController(text: value),
      ));
    });
  }

  void _removeCustomField(int index) {
    setState(() {
      final pair = _dynamicFieldControllers.removeAt(index);
      pair.key.dispose();
      pair.value.dispose();
    });
  }

  LeadModel _buildCurrentLead() {
    final Map<String, String> extra = {};
    for (final pair in _dynamicFieldControllers) {
      final k = pair.key.text.trim();
      final v = pair.value.text.trim();
      if (k.isNotEmpty && v.isNotEmpty) {
        extra[k] = v;
      }
    }

    return LeadModel(
      id: _leadId,
      companyName: _companyController.text.trim(),
      mailId: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      contactPersonName: _contactPersonController.text.trim(),
      address: _addressController.text.trim(),
      notes: _notesController.text.trim(),
      extraFields: extra,
      imagePath: _imagePath,
      scannedAt: _scannedAt,
      isFavorite: _isFavorite,
    );
  }

  /// Extracts all flyer details dynamically with Gemini Flash Multimodal Vision
  Future<void> _extractAllWithGemini(ImageSource source) async {
    final settings = context.read<SettingsProvider>();
    final picked = await _picker.pickImage(source: source, imageQuality: 88);
    if (picked == null) return;

    final imageFile = File(picked.path);

    setState(() {
      _isExtractingWithAi = true;
      _imagePath = imageFile.path;
    });

    try {
      final extracted = await GeminiVisionService.extractAllDetailsFromImage(
        imageFile,
        explicitApiKey: settings.geminiApiKey,
      );

      if (!mounted) return;

      setState(() {
        if (extracted.companyName.isNotEmpty) {
          _companyController.text = extracted.companyName;
        }
        if (extracted.mailId.isNotEmpty) {
          _emailController.text = extracted.mailId;
        }
        if (extracted.phoneNumber.isNotEmpty) {
          _phoneController.text = extracted.phoneNumber;
        }
        if (extracted.contactPersonName.isNotEmpty) {
          _contactPersonController.text = extracted.contactPersonName;
        }
        if (extracted.address.isNotEmpty) {
          _addressController.text = extracted.address;
        }
        if (extracted.notes.isNotEmpty) {
          _notesController.text = extracted.notes;
        }

        // Add extracted extra dynamic fields
        extracted.extraFields.forEach((k, v) {
          final existingIndex = _dynamicFieldControllers.indexWhere(
            (p) => p.key.text.trim().toLowerCase() == k.trim().toLowerCase(),
          );
          if (existingIndex >= 0) {
            _dynamicFieldControllers[existingIndex].value.text = v;
          } else {
            _dynamicFieldControllers.add((
              key: TextEditingController(text: k),
              value: TextEditingController(text: v),
            ));
          }
        });
      });

      SnackbarHelper.showSuccess(
        context,
        'All details extracted & filled with Gemini AI!',
      );
    } catch (e) {
      if (mounted) {
        final err = e.toString().replaceAll('Exception: ', '');
        final userMsg = err.contains('503') || err.contains('UNAVAILABLE')
            ? 'Gemini AI servers are busy right now. Please try again in a moment.'
            : 'AI Extract failed: $err';
        SnackbarHelper.showError(context, userMsg);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExtractingWithAi = false;
        });
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      SnackbarHelper.showError(context, 'Please resolve validation errors.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final leadProvider = context.read<LeadProvider>();
    final leadToSave = _buildCurrentLead();

    final isNew = widget.initialLead == null || widget.initialLead!.id.isEmpty;
    final success = isNew
        ? await leadProvider.addLead(leadToSave)
        : await leadProvider.updateLead(leadToSave);

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (success) {
        SnackbarHelper.showSuccess(
          context,
          isNew ? 'Lead saved successfully.' : 'Lead updated successfully.',
        );
        Navigator.of(context).pop();
      } else {
        SnackbarHelper.showError(context, 'Failed to save lead.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isNew = widget.initialLead == null || widget.initialLead!.id.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'New Lead Entry' : 'Edit Lead Details'),
        actions: [
          IconButton(
            tooltip: _isFavorite ? 'Remove Star' : 'Star Lead',
            icon: Icon(
              _isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _isFavorite ? const Color(0xFFF59E0B) : null,
              size: 26,
            ),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 1. AI Vision Deep Extractor Card
            _buildAiExtractorCard(context, isDark),
            const SizedBox(height: 18),

            // 2. Primary Information Bento Card
            _buildBentoSection(
              context,
              title: 'Primary Information',
              icon: Icons.business_rounded,
              accentColor: AppTheme.primaryColor,
              children: [
                TextFormField(
                  controller: _companyController,
                  decoration: const InputDecoration(
                    labelText: 'Company / Business Name',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  validator: (val) => Validators.validateRequired(val, 'Company Name'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _contactPersonController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Person Name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 3. Contact & Communication Bento Card
            _buildBentoSection(
              context,
              title: 'Contact & Communication',
              icon: Icons.contact_phone_rounded,
              accentColor: AppTheme.secondaryColor,
              children: [
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  textInputAction: TextInputAction.next,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 4. Physical Location Bento Card
            _buildBentoSection(
              context,
              title: 'Physical Location',
              icon: Icons.location_on_rounded,
              accentColor: AppTheme.accentPurple,
              children: [
                TextFormField(
                  controller: _addressController,
                  minLines: 1,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    labelText: 'Full Address / Location',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    alignLabelWithHint: true,
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 5. Dynamic Custom Fields Bento Card
            _buildDynamicFieldsSection(context, isDark),
            const SizedBox(height: 18),

            // 6. Additional Notes Bento Card
            _buildBentoSection(
              context,
              title: 'Additional Notes',
              icon: Icons.note_alt_outlined,
              accentColor: AppTheme.accentPink,
              children: [
                TextFormField(
                  controller: _notesController,
                  minLines: 2,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    labelText: 'Notes, Requirements or Keywords',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // 7. Save Action Button
            CustomGradientButton(
              label: isNew ? 'Save Scanned Lead' : 'Update Lead Details',
              icon: Icons.check_circle_rounded,
              isLoading: _isSaving,
              onPressed: _handleSave,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAiExtractorCard(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.aiGradientStart.withValues(alpha: isDark ? 0.25 : 0.12),
            AppTheme.aiGradientMid.withValues(alpha: isDark ? 0.25 : 0.12),
            AppTheme.aiGradientEnd.withValues(alpha: isDark ? 0.25 : 0.12),
          ],
        ),
        border: Border.all(
          color: AppTheme.aiGradientMid.withValues(alpha: isDark ? 0.5 : 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.aiGradientStart, AppTheme.aiGradientEnd],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gemini AI All-Detail Extractor',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Extracts all text & builds custom dynamic fields',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isExtractingWithAi) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Gemini Vision is inspecting flyer layout & extracting all fields...',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: AppTheme.aiGradientStart.withValues(alpha: 0.6),
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt_rounded, size: 18),
                    label: const Text(
                      'AI Camera',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _extractAllWithGemini(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: AppTheme.aiGradientEnd.withValues(alpha: 0.6),
                      ),
                    ),
                    icon: const Icon(Icons.photo_library_rounded, size: 18),
                    label: const Text(
                      'AI Gallery',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _extractAllWithGemini(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBentoSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color accentColor,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF243048) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDynamicFieldsSection(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF243048) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentEmerald.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.data_object_rounded,
                      color: AppTheme.accentEmerald,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Custom Extracted Fields',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _addCustomField(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'Add Field',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          if (_dynamicFieldControllers.isEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'No custom fields added yet. Tap "Add Field" or use "Gemini AI All-Detail Extractor" to automatically detect custom attributes (e.g., Job Title, Salary, Website, Skills).',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _dynamicFieldControllers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final pair = _dynamicFieldControllers[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Field Header: Field Name input + Remove Button
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: pair.key,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Attribute / Field Name',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _removeCustomField(index),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  color: Color(0xFFEF4444),
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Full-width Multi-line Value Input (Shows FULL text without horizontal scroll)
                      TextFormField(
                        controller: pair.value,
                        minLines: 1,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Extracted Value',
                          alignLabelWithHint: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
