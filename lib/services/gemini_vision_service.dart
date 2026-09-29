import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/ad_lead_model.dart';
import '../models/lead_model.dart';

/// Direct Multimodal Vision Service powered by Google Generative AI (Gemini Flash).
/// Performs layout-aware, typography-hierarchy extraction directly on flyer images
/// with strict JSON Schema outputs, multi-model auto-fallback, and dynamic field generation.
class GeminiVisionService {
  // Resolves API key from explicit param -> .env file -> --dart-define
  static String resolveApiKey([String? explicitApiKey]) {
    if (explicitApiKey != null && explicitApiKey.trim().isNotEmpty) {
      return explicitApiKey.trim();
    }
    final envKey = dotenv.env['GEMINI_API_KEY'];
    if (envKey != null && envKey.trim().isNotEmpty) {
      return envKey.trim();
    }
    return const String.fromEnvironment('GEMINI_API_KEY');
  }

  /// Returns candidate model list with priority
  static List<String> _getCandidateModels([String? preferredModel]) {
    final envModel = dotenv.env['GEMINI_MODEL'];
    final candidates = <String>[
      if (preferredModel != null && preferredModel.isNotEmpty) preferredModel,
      if (envModel != null && envModel.isNotEmpty) envModel,
      'gemini-1.5-flash',
      'gemini-1.5-flash-latest',
      'gemini-2.0-flash',
      'gemini-2.0-flash-exp',
      'gemini-3.6-flash',
      'gemini-1.5-pro',
    ];
    // Remove duplicates while preserving order
    return candidates.toSet().toList();
  }

  /// Extracts lead information directly from flyer image using Gemini Flash Multimodal Vision.
  static Future<AdLeadModel> extractLeadDirectlyFromImage(
    File imageFile, {
    String? explicitApiKey,
    String? modelName,
  }) async {
    final apiKey = resolveApiKey(explicitApiKey);

    if (apiKey.isEmpty) {
      throw Exception(
        'GEMINI_API_KEY is not defined. Add it to your .env file or Settings.',
      );
    }

    final schema = Schema.object(
      properties: {
        'companyName': Schema.string(
          description:
              'The authentic name of the hiring organization, business, or company. '
              'STRICT: Do NOT output recruitment headlines (e.g., "WE ARE HIRING", "JOB VACANCY", "WANTED").',
        ),
        'mailId': Schema.string(
          description:
              'A valid email address extracted from the flyer, or an empty string if absent.',
        ),
        'phoneNumber': Schema.string(
          description:
              'Primary telephone/mobile contact number, or an empty string if absent.',
        ),
        'contactPersonName': Schema.string(
          description:
              'The name of the individual HR recruiter, manager, or contact person, or an empty string if none is named.',
        ),
        'address': Schema.string(
          description:
              'Physical street, building, or location address. '
              'STRICT: Do NOT include phone numbers, emails, or job requirements in this field.',
        ),
      },
      requiredProperties: [
        'companyName',
        'mailId',
        'phoneNumber',
        'contactPersonName',
        'address',
      ],
    );

    final imageBytes = await imageFile.readAsBytes();
    final imagePart = DataPart('image/jpeg', imageBytes);

    final promptPart = TextPart('''
Analyze this advertisement, job poster, business card, or promotional flyer image.
Extract the 5 required lead attributes into the defined JSON schema format.

Rules:
1. "companyName": Identify the sponsoring brand or business organization (typically prominent at the top or in the header/logo). Reject slogans like "We Are Hiring", "Urgent Requirement", or "Walk-In Interview".
2. "contactPersonName": Only include a human person name if explicitly labeled (e.g., "Contact: Rajesh", "Manager: Sarah", "HR: John"). Do NOT put the company name here.
3. "address": Extract only genuine geographical/physical location details. Never mix contact numbers or emails into the address.
4. "phoneNumber": Extract the primary inquiry contact number.
5. "mailId": Extract clean email address.
6. If an attribute is missing or ambiguous, return an empty string "". Never hallucinate fake information.
''');

    final candidateModels = _getCandidateModels(modelName);
    Object? lastException;

    for (final candidate in candidateModels) {
      try {
        final model = GenerativeModel(
          model: candidate,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            responseSchema: schema,
            temperature: 0.0,
          ),
        );

        final response = await model.generateContent([
          Content.multi([promptPart, imagePart])
        ]);

        final jsonText = response.text;
        if (jsonText != null && jsonText.trim().isNotEmpty) {
          final Map<String, dynamic> parsedData =
              jsonDecode(jsonText) as Map<String, dynamic>;
          return AdLeadModel.fromMap(parsedData);
        }
      } catch (e) {
        lastException = e;
        // Continue to fallback model if 503, 404, or 429 encountered
        final errStr = e.toString();
        if (errStr.contains('503') || errStr.contains('404') || errStr.contains('429') || errStr.contains('UNAVAILABLE')) {
          await Future.delayed(const Duration(milliseconds: 600));
          continue;
        }
        rethrow;
      }
    }

    throw lastException ?? Exception('All Gemini Vision models were unavailable.');
  }

  /// Deep Multimodal Extraction: Extracts ALL details from the flyer image,
  /// including standard attributes and all extra dynamic key-value details.
  static Future<LeadModel> extractAllDetailsFromImage(
    File imageFile, {
    String? explicitApiKey,
    String? modelName,
  }) async {
    final apiKey = resolveApiKey(explicitApiKey);

    if (apiKey.isEmpty) {
      throw Exception(
        'GEMINI_API_KEY is not defined. Add it to your .env file or Settings.',
      );
    }

    final schema = Schema.object(
      properties: {
        'companyName': Schema.string(
          description: 'Official company, business, or brand name.',
        ),
        'mailId': Schema.string(
          description: 'Email address, or empty string.',
        ),
        'phoneNumber': Schema.string(
          description: 'Contact phone number, or empty string.',
        ),
        'contactPersonName': Schema.string(
          description: 'HR manager, recruiter, or contact person name, or empty string.',
        ),
        'address': Schema.string(
          description: 'Physical address or location.',
        ),
        'notes': Schema.string(
          description: 'Concise summary of the advertisement or hiring post.',
        ),
        'extraFields': Schema.array(
          description:
              'All other details extracted from the flyer (e.g. Job Title, Salary, Experience, Skills, Website, Interview Date, Working Hours, Benefits, Requirements).',
          items: Schema.object(
            properties: {
              'key': Schema.string(
                description: 'Field name (e.g. "Job Title", "Salary", "Experience", "Skills", "Website", "Walk-In Date").',
              ),
              'value': Schema.string(
                description: 'Field value extracted from the flyer.',
              ),
            },
            requiredProperties: ['key', 'value'],
          ),
        ),
      },
      requiredProperties: [
        'companyName',
        'mailId',
        'phoneNumber',
        'contactPersonName',
        'address',
        'notes',
        'extraFields',
      ],
    );

    final imageBytes = await imageFile.readAsBytes();
    final imagePart = DataPart('image/jpeg', imageBytes);

    final promptPart = TextPart('''
Analyze this advertisement, hiring banner, flyer, or visiting card in detail.
Extract ALL information accurately into the defined JSON format.

1. "companyName": Genuine business/brand name.
2. "mailId": Email address.
3. "phoneNumber": Primary contact phone number.
4. "contactPersonName": Named recruiter/contact person.
5. "address": Office/store address.
6. "notes": Brief overview of the ad.
7. "extraFields": Extract EVERY other detail visible on the ad as key-value pairs (e.g., Job Position, Salary / Compensation, Required Experience, Qualification / Degree, Key Skills, Interview Dates / Walk-in Timings, Website / URL, Department, Benefits). Do not hallucinate. Only include fields actually mentioned in the image.
''');

    final candidateModels = _getCandidateModels(modelName);
    Object? lastException;

    for (final candidate in candidateModels) {
      try {
        final model = GenerativeModel(
          model: candidate,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            responseSchema: schema,
            temperature: 0.0,
          ),
        );

        final response = await model.generateContent([
          Content.multi([promptPart, imagePart])
        ]);

        final jsonText = response.text;
        if (jsonText != null && jsonText.trim().isNotEmpty) {
          final Map<String, dynamic> parsedData =
              jsonDecode(jsonText) as Map<String, dynamic>;

          final Map<String, String> dynamicExtra = {};
          if (parsedData['extraFields'] is List) {
            for (final item in parsedData['extraFields'] as List) {
              if (item is Map && item['key'] != null && item['value'] != null) {
                final k = item['key'].toString().trim();
                final v = item['value'].toString().trim();
                if (k.isNotEmpty && v.isNotEmpty) {
                  dynamicExtra[k] = v;
                }
              }
            }
          }

          return LeadModel(
            companyName: parsedData['companyName']?.toString().trim() ?? '',
            mailId: parsedData['mailId']?.toString().trim() ?? '',
            phoneNumber: parsedData['phoneNumber']?.toString().trim() ?? '',
            contactPersonName: parsedData['contactPersonName']?.toString().trim() ?? '',
            address: parsedData['address']?.toString().trim() ?? '',
            notes: parsedData['notes']?.toString().trim() ?? '',
            extraFields: dynamicExtra,
            imagePath: imageFile.path,
            scannedAt: DateTime.now(),
          );
        }
      } catch (e) {
        lastException = e;
        final errStr = e.toString();
        // If 503 high demand, 404 not found, or 429 rate limit, attempt next candidate model
        if (errStr.contains('503') || errStr.contains('404') || errStr.contains('429') || errStr.contains('UNAVAILABLE')) {
          await Future.delayed(const Duration(milliseconds: 600));
          continue;
        }
        rethrow;
      }
    }

    throw lastException ?? Exception('Gemini servers are currently experiencing high demand. Please try again or use offline scan.');
  }

  /// Helper converting extracted AdLeadModel to domain LeadModel.
  static Future<LeadModel> extractDomainLeadFromImage(
    File imageFile, {
    String? explicitApiKey,
    String? modelName,
  }) async {
    return extractAllDetailsFromImage(
      imageFile,
      explicitApiKey: explicitApiKey,
      modelName: modelName,
    );
  }
}
