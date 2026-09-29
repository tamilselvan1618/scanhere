import '../core/constants/app_constants.dart';

/// Form field validators for business lead attributes.
class Validators {
  /// Validates required text field.
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates company name.
  static String? validateCompanyName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Company or Business name is required';
    }
    if (value.trim().length < 2) {
      return 'Company name must be at least 2 characters';
    }
    return null;
  }

  /// Validates email if provided.
  static String? validateEmailOptional(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!AppConstants.emailPattern.hasMatch(value.trim())) {
      return 'Enter a valid email address (e.g. name@company.com)';
    }
    return null;
  }

  /// Validates phone number if provided.
  static String? validatePhoneOptional(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7 || digits.length > 15) {
      return 'Enter a valid phone number (7–15 digits)';
    }
    return null;
  }

  /// Validates email (alias).
  static String? validateEmail(String? value) => validateEmailOptional(value);

  /// Validates phone (alias).
  static String? validatePhone(String? value) => validatePhoneOptional(value);

  /// Ensures at least one primary identification field is non-empty.
  static bool hasMinimumRequiredFields({
    required String companyName,
    required String phoneNumber,
    required String mailId,
  }) {
    return companyName.trim().isNotEmpty ||
        phoneNumber.trim().isNotEmpty ||
        mailId.trim().isNotEmpty;
  }
}

/// Alias for backwards-compatibility
typedef AppValidators = Validators;
