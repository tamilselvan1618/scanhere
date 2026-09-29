import 'dart:convert';

/// Immutable domain model representing parsed advertisement lead attributes.
class AdLeadModel {
  final String companyName;
  final String mailId;
  final String phoneNumber;
  final String contactPersonName;
  final String address;

  const AdLeadModel({
    this.companyName = '',
    this.mailId = '',
    this.phoneNumber = '',
    this.contactPersonName = '',
    this.address = '',
  });

  /// Factory constructor to create an instance from a map (supports camelCase and snake_case).
  factory AdLeadModel.fromMap(Map<String, dynamic> map) {
    return AdLeadModel(
      companyName: (map['company_name'] ?? map['companyName']) as String? ?? '',
      mailId: (map['mail_id'] ?? map['mailId'] ?? map['email']) as String? ?? '',
      phoneNumber: (map['phone_number'] ?? map['phoneNumber'] ?? map['phone']) as String? ?? '',
      contactPersonName: (map['contact_person_name'] ?? map['contactPersonName'] ?? map['contactPerson']) as String? ?? '',
      address: (map['address'] ?? map['location']) as String? ?? '',
    );
  }

  /// Converts the model instance to a Map structure.
  Map<String, dynamic> toMap() {
    return {
      'company_name': companyName,
      'mail_id': mailId,
      'phone_number': phoneNumber,
      'contact_person_name': contactPersonName,
      'address': address,
    };
  }

  /// Factory constructor from serialized JSON string.
  factory AdLeadModel.fromJson(String source) =>
      AdLeadModel.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Serializes instance into a JSON string.
  String toJson() => json.encode(toMap());

  /// Returns a copy of the model with optional updated fields.
  AdLeadModel copyWith({
    String? companyName,
    String? mailId,
    String? phoneNumber,
    String? contactPersonName,
    String? address,
  }) {
    return AdLeadModel(
      companyName: companyName ?? this.companyName,
      mailId: mailId ?? this.mailId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      address: address ?? this.address,
    );
  }

  /// True if all 5 attributes are blank or whitespace.
  bool get isEmpty =>
      companyName.trim().isEmpty &&
      mailId.trim().isEmpty &&
      phoneNumber.trim().isEmpty &&
      contactPersonName.trim().isEmpty &&
      address.trim().isEmpty;

  /// True if at least one field has non-empty text.
  bool get isNotEmpty => !isEmpty;

  @override
  String toString() {
    return 'AdLeadModel(companyName: $companyName, mailId: $mailId, phoneNumber: $phoneNumber, contactPersonName: $contactPersonName, address: $address)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdLeadModel &&
        other.companyName == companyName &&
        other.mailId == mailId &&
        other.phoneNumber == phoneNumber &&
        other.contactPersonName == contactPersonName &&
        other.address == address;
  }

  @override
  int get hashCode =>
      companyName.hashCode ^
      mailId.hashCode ^
      phoneNumber.hashCode ^
      contactPersonName.hashCode ^
      address.hashCode;
}
