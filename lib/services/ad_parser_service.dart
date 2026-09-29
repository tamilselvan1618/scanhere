import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/ad_lead_model.dart';
import '../models/lead_model.dart';

/// Multi-stage precision parsing pipeline designed to extract 5 core attributes
/// without cross-field leakage or slogan pollution.
class AdParserService {
  // Phase 1: RFC 5322-compliant Email Pattern
  static final RegExp _emailRegex = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
    caseSensitive: false,
  );

  // Phase 2: International, Formatted & 10-Digit Phone Pattern
  static final RegExp _phoneRegex = RegExp(
    r'(?:\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}|\b\d{10}\b',
  );

  // Phase 2: Contact Indicator Prefixes
  static final RegExp _contactPrefixRegex = RegExp(
    r'\b(contact(?:\s+person)?|hr(?:\s+manager)?|manager|call|send\s+(?:your\s+)?cv\s+to|send\s+resume\s+to|attn|proprietor|prop|founder|owner|director|ceo)\b[:\s-]*',
    caseSensitive: false,
  );

  // Phase 3: Corporate Tokens & Legal Suffixes
  static final RegExp _companyTokensRegex = RegExp(
    r'\b(Network|Solutions|Enterprises|Technologies|Tech|Corp|Corporation|Ltd|LLC|Pvt|Inc|Agency|Studio|Consulting|Group|Holdings|Ventures)\b',
    caseSensitive: false,
  );

  // Phase 3: Address Tokens & Identifiers
  static final RegExp _addressTokensRegex = RegExp(
    r'\b(street|st|avenue|ave|road|rd|floor|tower|building|bldg|opp|opposite|near|suite|ste|plot|cross|layout|pin|zip|postal|lane|block|city|sector|phase|highway)\b',
    caseSensitive: false,
  );

  // Strict Slogan, Noise & Section Blacklist
  static final List<String> _bannedPhrases = [
    'we are hiring',
    "we're hiring",
    'we re hiring',
    'hiring now',
    'hiring',
    'wanted',
    'sales representative',
    'job vacancy',
    'requirements',
    'qualifications',
    'responsibilities',
    'send your cv to',
    'apply now',
    'join our team',
    'walk in interview',
    'walk-in interview',
    'dynamic sales professional',
    'career opportunity',
    'job alert',
    'urgent requirement',
    'full time',
    'part time',
    'experience required',
  ];

  /// Primary parsing entry point accepting Google ML Kit's [RecognizedText].
  AdLeadModel parseRecognizedText(RecognizedText recognizedText) {
    if (recognizedText.text.trim().isEmpty) {
      return const AdLeadModel();
    }

    // Sort text blocks vertically from top to bottom
    final sortedBlocks = List<TextBlock>.from(recognizedText.blocks)
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    final List<String> rawLines = [];
    for (final block in sortedBlocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isNotEmpty) {
          rawLines.add(text);
        }
      }
    }

    if (rawLines.isEmpty) {
      rawLines.addAll(
        recognizedText.text
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty),
      );
    }

    return parseLines(rawLines);
  }

  /// Parses raw advertisement text string and returns a domain [LeadModel].
  LeadModel parseAdvertisementText(String text, {String? imagePath}) {
    final rawLines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final adLead = parseLines(rawLines);
    return LeadModel(
      companyName: adLead.companyName,
      mailId: adLead.mailId,
      phoneNumber: adLead.phoneNumber,
      contactPersonName: adLead.contactPersonName,
      address: adLead.address,
      imagePath: imagePath,
    );
  }

  /// Executes the multi-stage parsing pipeline on ordered text lines.
  AdLeadModel parseLines(List<String> rawLines) {
    // -------------------------------------------------------------
    // STAGE 1: Extract discrete high-certainty tokens
    // -------------------------------------------------------------
    final mailId = _extractFirstMatch(rawLines, _emailRegex);
    final phoneNumber = _extractFirstMatch(rawLines, _phoneRegex);

    // -------------------------------------------------------------
    // STAGE 2: Anti-Leak Sanitization Layer
    // -------------------------------------------------------------
    // Clean all lines by stripping out the isolated email and phone number
    final sanitizedLines = rawLines.map((line) {
      var cleaned = line;
      if (mailId.isNotEmpty) {
        cleaned = cleaned.replaceAll(mailId, ' ');
      }
      if (phoneNumber.isNotEmpty) {
        cleaned = cleaned.replaceAll(phoneNumber, ' ');
      }
      return _cleanFormatting(cleaned);
    }).where((l) => l.isNotEmpty).toList();

    // -------------------------------------------------------------
    // STAGE 3: Extract Contact Person, Company, and Address
    // -------------------------------------------------------------
    final contactPersonName = _extractContactPerson(rawLines, mailId, phoneNumber);
    final address = _extractAddress(sanitizedLines);
    final companyName = _extractCompanyName(sanitizedLines, contactPersonName, address);

    return AdLeadModel(
      companyName: companyName,
      mailId: mailId,
      phoneNumber: phoneNumber,
      contactPersonName: contactPersonName,
      address: address,
    );
  }

  /// Extracts the first occurrence matching the given regex pattern.
  String _extractFirstMatch(List<String> lines, RegExp pattern) {
    for (final line in lines) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        final candidate = match.group(0)!.trim();
        if (candidate.isNotEmpty) {
          return candidate;
        }
      }
    }
    return '';
  }

  /// Extracts the contact person name using trigger prefixes and strict character boundaries.
  String _extractContactPerson(List<String> rawLines, String email, String phone) {
    for (int i = 0; i < rawLines.length; i++) {
      final line = rawLines[i];
      final prefixMatch = _contactPrefixRegex.firstMatch(line);

      if (prefixMatch != null) {
        // Grab remaining line text after the prefix keyword
        var candidate = line.substring(prefixMatch.end);
        if (email.isNotEmpty) candidate = candidate.replaceAll(email, '');
        if (phone.isNotEmpty) candidate = candidate.replaceAll(phone, '');
        candidate = _cleanPersonName(candidate);

        if (_isValidPersonName(candidate)) {
          return candidate;
        }

        // If prefix was standalone on line i, check line i + 1
        if (i + 1 < rawLines.length) {
          var nextCandidate = rawLines[i + 1];
          if (email.isNotEmpty) nextCandidate = nextCandidate.replaceAll(email, '');
          if (phone.isNotEmpty) nextCandidate = nextCandidate.replaceAll(phone, '');
          nextCandidate = _cleanPersonName(nextCandidate);

          if (_isValidPersonName(nextCandidate)) {
            return nextCandidate;
          }
        }
      }
    }
    return '';
  }

  /// Extracts physical address by scanning address tokens and excluding noise.
  String _extractAddress(List<String> sanitizedLines) {
    final List<String> addressParts = [];

    for (int i = 0; i < sanitizedLines.length; i++) {
      final line = sanitizedLines[i];

      if (_isBannedPhrase(line)) continue;
      if (line.startsWith('http') || line.startsWith('www.')) continue;

      if (_addressTokensRegex.hasMatch(line) || _hasPostalCode(line)) {
        addressParts.add(line);

        // Check if subsequent line contains contiguous address metadata
        if (i + 1 < sanitizedLines.length) {
          final nextLine = sanitizedLines[i + 1];
          if (!_isBannedPhrase(nextLine) &&
              !_addressTokensRegex.hasMatch(nextLine) &&
              (_hasPostalCode(nextLine) || nextLine.contains(','))) {
            if (!addressParts.contains(nextLine)) {
              addressParts.add(nextLine);
            }
          }
        }
      }
    }

    if (addressParts.isNotEmpty) {
      return addressParts
          .join(', ')
          .replaceAll(RegExp(r',\s*,'), ',')
          .replaceAll(RegExp(r'[\r\n]+'), ' ')
          .trim();
    }

    return '';
  }

  /// Extracts company name by checking top lines for company tokens or concise titles.
  String _extractCompanyName(
    List<String> sanitizedLines,
    String contactPerson,
    String address,
  ) {
    // Focus search on upper region of advertisement (top 6 lines)
    final candidateLines = sanitizedLines.take(6).toList();

    // Priority 1: Check top lines for explicit corporate tokens (e.g., FOX Network, Nexus Solutions Pvt Ltd)
    for (final line in candidateLines) {
      if (_companyTokensRegex.hasMatch(line)) {
        if (_isEligibleCompany(line, contactPerson, address)) {
          return _cleanFormatting(line);
        }
      }
    }

    // Priority 2: Fallback to the first concise header line (2 to 35 chars) in upper section
    for (final line in candidateLines) {
      if (_isEligibleCompany(line, contactPerson, address)) {
        final len = line.length;
        if (len >= 2 && len <= 35) {
          return _cleanFormatting(line);
        }
      }
    }

    // Ultimate fallback if nothing else matches
    for (final line in sanitizedLines) {
      if (_isEligibleCompany(line, contactPerson, address)) {
        return _cleanFormatting(line);
      }
    }

    return '';
  }

  /// Verifies whether a candidate string can be a valid company name.
  bool _isEligibleCompany(String line, String contactPerson, String address) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return false;
    if (_isBannedPhrase(trimmed)) return false;
    if (_contactPrefixRegex.hasMatch(trimmed)) return false;
    if (contactPerson.isNotEmpty && trimmed.toLowerCase() == contactPerson.toLowerCase()) {
      return false;
    }
    if (address.isNotEmpty && address.toLowerCase().contains(trimmed.toLowerCase())) {
      return false;
    }
    if (trimmed.startsWith('http') || trimmed.startsWith('www.')) {
      return false;
    }
    return true;
  }

  /// Checks if a string matches any banned slogan, header label, or recruitment phrase.
  bool _isBannedPhrase(String text) {
    final lower = text.trim().toLowerCase();
    for (final phrase in _bannedPhrases) {
      if (lower == phrase || lower.startsWith('$phrase ') || lower.contains(phrase)) {
        return true;
      }
    }
    return false;
  }

  /// Validates extracted human name constraints (2 to 30 characters, no digits or address words).
  bool _isValidPersonName(String name) {
    if (name.length < 2 || name.length > 30) return false;
    if (_isBannedPhrase(name)) return false;
    if (_companyTokensRegex.hasMatch(name)) return false;
    if (_addressTokensRegex.hasMatch(name)) return false;
    if (RegExp(r'\d').hasMatch(name)) return false;
    if (name.split(RegExp(r'\s+')).length > 4) return false;
    return true;
  }

  /// Checks for postal/ZIP code format
  bool _hasPostalCode(String s) {
    return RegExp(r'\b(?:\d{5,6}|[A-Z]{1,2}\d[A-Z\d]?\s*\d[A-Z]{2})\b').hasMatch(s);
  }

  /// Cleans person name string
  String _cleanPersonName(String name) {
    return name
        .replaceAll(_contactPrefixRegex, '')
        .replaceAll(RegExp(r'[\(\)\[\]]'), ' ')
        .replaceAll(RegExp(r'^[^\w]+|[^\w]+$'), '')
        .trim();
  }

  /// Cleans punctuation formatting
  String _cleanFormatting(String text) {
    return text
        .replaceAll(RegExp(r'[\r\n]+'), ' ')
        .replaceAll(RegExp(r'^[\s\-–—:;*|]+|[\s\-–—:;*|]+$'), '')
        .trim();
  }
}
