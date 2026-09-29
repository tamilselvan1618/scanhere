import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/ad_lead_data.dart';

/// Service responsible for executing Latin script OCR on advertisement images
/// and parsing targeted business attributes using regex heuristics and structural layout analysis.
class OcrParserService {
  final TextRecognizer _textRecognizer;

  OcrParserService({TextRecognizer? recognizer})
      : _textRecognizer = recognizer ??
            TextRecognizer(script: TextRecognitionScript.latin);

  // Phone number extraction regex targeting international, local, and 10-digit formats
  static final RegExp _phoneRegex = RegExp(
    r'(?:\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}|\b\d{10}\b',
  );

  // Prefix matching for company owner/executive titles
  static final RegExp _ownerPrefixRegex = RegExp(
    r'\b(owner|founder|proprietor|prop|director|ceo|managing partner)\b[:\s-]*',
    caseSensitive: false,
  );

  // Legal suffixes and corporate entity descriptors for primary company name detection
  static final RegExp _companySuffixRegex = RegExp(
    r'\b(Ltd|LLC|Pvt|Inc|Enterprises|Solutions|Agency)\b',
    caseSensitive: false,
  );

  /// Performs on-device OCR inference on the provided [imageFile]
  /// and returns parsed [AdLeadData].
  Future<AdLeadData> parseImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return parseRecognizedText(recognizedText);
  }

  /// Performs on-device OCR inference on the image located at [filePath]
  Future<AdLeadData> parseImagePath(String filePath) async {
    final inputImage = InputImage.fromFilePath(filePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return parseRecognizedText(recognizedText);
  }

  /// Parses an already resolved [RecognizedText] payload from Google ML Kit.
  AdLeadData parseRecognizedText(RecognizedText recognizedText) {
    if (recognizedText.text.trim().isEmpty) {
      return const AdLeadData();
    }

    // Sort text blocks vertically by bounding box top coordinate to preserve natural reading order
    final sortedBlocks = List<TextBlock>.from(recognizedText.blocks)
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    // Flatten all lines across sorted blocks
    final List<String> allLines = [];
    for (final block in sortedBlocks) {
      for (final line in block.lines) {
        final cleaned = line.text.trim();
        if (cleaned.isNotEmpty) {
          allLines.add(cleaned);
        }
      }
    }

    // If block-level extraction resulted in empty lines, fallback to raw text splitting
    if (allLines.isEmpty) {
      allLines.addAll(
        recognizedText.text
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty),
      );
    }

    final phone = _extractPhoneNumber(allLines);
    final owner = _extractCompanyOwner(allLines);
    final company = _extractCompanyName(allLines, owner);

    return AdLeadData(
      companyName: company,
      phoneNumber: phone,
      companyOwner: owner,
    );
  }

  /// Extracts phone number matching international, local, or 10-digit formats.
  String _extractPhoneNumber(List<String> lines) {
    for (final line in lines) {
      final match = _phoneRegex.firstMatch(line);
      if (match != null) {
        return match.group(0)?.trim() ?? '';
      }
    }
    return '';
  }

  /// Extracts company owner by detecting keywords and capturing subsequent name tokens.
  String _extractCompanyOwner(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final match = _ownerPrefixRegex.firstMatch(line);
      if (match != null) {
        // Extract content after the matched prefix on the same line
        final candidateSameLine = line.substring(match.end).trim();
        final sanitizedSameLine = _cleanExtractedName(candidateSameLine);

        if (sanitizedSameLine.isNotEmpty) {
          return sanitizedSameLine;
        }

        // If prefix was standalone on line i, attempt to grab line i + 1
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1].trim();
          // Verify next line isn't a phone number, url, or another title prefix
          if (!_phoneRegex.hasMatch(nextLine) &&
              !_ownerPrefixRegex.hasMatch(nextLine) &&
              !_isProminentNumber(nextLine)) {
            final sanitizedNextLine = _cleanExtractedName(nextLine);
            if (sanitizedNextLine.isNotEmpty) {
              return sanitizedNextLine;
            }
          }
        }
      }
    }
    return '';
  }

  /// Extracts company name via primary legal suffix check or fallback to topmost header.
  String _extractCompanyName(List<String> lines, String knownOwner) {
    // 1. Primary Strategy: Match brand keywords or legal suffixes
    for (final line in lines) {
      if (_companySuffixRegex.hasMatch(line)) {
        // Ensure this line isn't just a phone number or owner line
        if (!_phoneRegex.hasMatch(line) &&
            !_ownerPrefixRegex.hasMatch(line) &&
            line.trim() != knownOwner) {
          return _cleanHeaderString(line);
        }
      }
    }

    // 2. Fallback Strategy: Top-most prominent text line excluding numbers and owner labels
    for (final line in lines) {
      if (_isEligibleHeader(line, knownOwner)) {
        return _cleanHeaderString(line);
      }
    }

    // If all else fails, return the first available line
    return lines.isNotEmpty ? _cleanHeaderString(lines.first) : '';
  }

  /// Evaluates whether a line qualifies as a candidate header line.
  bool _isEligibleHeader(String line, String knownOwner) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return false;
    if (_phoneRegex.hasMatch(trimmed)) return false;
    if (_ownerPrefixRegex.hasMatch(trimmed)) return false;
    if (_isProminentNumber(trimmed)) return false;
    if (knownOwner.isNotEmpty && trimmed.toLowerCase() == knownOwner.toLowerCase()) {
      return false;
    }
    // Avoid pure URLs or email addresses
    if (trimmed.contains('@') || trimmed.startsWith('www.') || trimmed.startsWith('http')) {
      return false;
    }
    return true;
  }

  /// Checks if the text consists mostly of numbers (e.g. pin codes, registration IDs)
  bool _isProminentNumber(String s) {
    final digitsCount = s.replaceAll(RegExp(r'\D'), '').length;
    return digitsCount > (s.length / 2);
  }

  /// Cleans punctuation and invalid characters from person names
  String _cleanExtractedName(String text) {
    return text
        .replaceAll(RegExp(r'^[:\s\-\.\,\|\/]+|[:\s\-\.\,\|\/]+$'), '')
        .trim();
  }

  /// Cleans header / company string
  String _cleanHeaderString(String text) {
    return text
        .replaceAll(RegExp(r'[\r\n]+'), ' ')
        .replaceAll(RegExp(r'^[\s\-\.\,\|\/\:\;\*]+|[\s\-\.\,\|\/\:\;\*]+$'), '')
        .trim();
  }

  /// Release native ML Kit resources
  void dispose() {
    _textRecognizer.close();
  }
}
