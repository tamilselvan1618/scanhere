import 'dart:convert';
import '../core/constants/app_constants.dart';
import '../core/network/api_client.dart';
import '../models/lead_model.dart';

/// Service connecting to Gemini 2.5 Flash API for cloud-assisted lead extraction.
class GeminiExtractionService {
  final ApiClient _apiClient;

  GeminiExtractionService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Extracts structured lead attributes from raw OCR text using Gemini 2.5 Flash.
  Future<LeadModel?> extractLead({
    required String rawOcrText,
    required String apiKey,
  }) async {
    if (apiKey.trim().isEmpty || rawOcrText.trim().isEmpty) {
      return null;
    }

    final prompt = '''
You are an expert advertisement parsing engine. Extract the 5 business lead attributes from the following unstructured advertisement text.

Rules:
1. Extract ONLY these fields: "company_name", "mail_id", "phone_number", "contact_person_name", "address".
2. Never hallucinate or invent fake information. If a field is missing in the text, return an empty string "".
3. Ignore promotional slogans (e.g. "We Are Hiring", "Urgent Vacancy", "Apply Now", "Walk-in Interview").
4. Return pure JSON format matching this exact schema:
{
  "company_name": "string",
  "mail_id": "string",
  "phone_number": "string",
  "contact_person_name": "string",
  "address": "string"
}

Raw Advertisement Text:
"""
$rawOcrText
"""
''';

    final requestPayload = {
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.0,
        "responseMimeType": "application/json"
      }
    };

    final url = '${AppConstants.geminiEndpoint}?key=$apiKey';

    try {
      final response = await _apiClient.post(url, data: requestPayload);

      if (response.statusCode == 200 && response.data != null) {
        final candidates = response.data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final jsonText = parts[0]['text'] as String?;
            if (jsonText != null) {
              final parsedMap = json.decode(_cleanJsonBlock(jsonText))
                  as Map<String, dynamic>;
              return LeadModel.fromMap(parsedMap);
            }
          }
        }
      }
    } catch (_) {
      // Gracefully fall back to offline parser
      return null;
    }
    return null;
  }

  String _cleanJsonBlock(String raw) {
    var cleaned = raw.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    }
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }
}
