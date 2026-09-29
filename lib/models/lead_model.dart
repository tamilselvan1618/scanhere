import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Domain entity representing a captured business advertisement lead with dynamic custom attributes.
class LeadModel {
  final String id;
  final String companyName;
  final String mailId;
  final String phoneNumber;
  final String contactPersonName;
  final String address;
  final String notes;
  final Map<String, String> extraFields;
  final String? imagePath;
  final DateTime scannedAt;
  final bool isFavorite;

  LeadModel({
    String? id,
    this.companyName = '',
    this.mailId = '',
    this.phoneNumber = '',
    this.contactPersonName = '',
    this.address = '',
    this.notes = '',
    Map<String, String>? extraFields,
    this.imagePath,
    DateTime? scannedAt,
    this.isFavorite = false,
  })  : id = id ?? const Uuid().v4(),
        extraFields = extraFields ?? const {},
        scannedAt = scannedAt ?? DateTime.now();

  /// Creates an empty LeadModel instance.
  factory LeadModel.empty() => LeadModel();

  /// Creates a LeadModel from a Map (supports camelCase & snake_case and dynamic extra fields).
  factory LeadModel.fromMap(Map<String, dynamic> map) {
    Map<String, String> parsedExtra = {};
    if (map['extra_fields'] != null) {
      if (map['extra_fields'] is Map) {
        parsedExtra = (map['extra_fields'] as Map)
            .map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
      }
    } else if (map['extraFields'] != null) {
      if (map['extraFields'] is Map) {
        parsedExtra = (map['extraFields'] as Map)
            .map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
      }
    }

    return LeadModel(
      id: (map['id'] ?? const Uuid().v4()) as String,
      companyName: (map['company_name'] ?? map['companyName']) as String? ?? '',
      mailId: (map['mail_id'] ?? map['mailId'] ?? map['email']) as String? ?? '',
      phoneNumber: (map['phone_number'] ?? map['phoneNumber'] ?? map['phone']) as String? ?? '',
      contactPersonName: (map['contact_person_name'] ?? map['contactPersonName'] ?? map['contactPerson']) as String? ?? '',
      address: (map['address'] ?? map['location']) as String? ?? '',
      notes: (map['notes'] ?? map['description']) as String? ?? '',
      extraFields: parsedExtra,
      imagePath: (map['image_path'] ?? map['imagePath']) as String?,
      scannedAt: map['scanned_at'] != null
          ? DateTime.parse(map['scanned_at'] as String)
          : (map['scannedAt'] != null
              ? DateTime.parse(map['scannedAt'] as String)
              : DateTime.now()),
      isFavorite: (map['is_favorite'] ?? map['isFavorite']) as bool? ?? false,
    );
  }

  /// Converts the LeadModel to a Map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_name': companyName,
      'mail_id': mailId,
      'phone_number': phoneNumber,
      'contact_person_name': contactPersonName,
      'address': address,
      'notes': notes,
      'extra_fields': extraFields,
      'image_path': imagePath,
      'scanned_at': scannedAt.toIso8601String(),
      'is_favorite': isFavorite,
    };
  }

  /// Deserializes a JSON string to LeadModel.
  factory LeadModel.fromJson(String source) =>
      LeadModel.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Serializes instance into a JSON string.
  String toJson() => json.encode(toMap());

  /// Returns a copy of the lead with updated fields.
  LeadModel copyWith({
    String? id,
    String? companyName,
    String? mailId,
    String? phoneNumber,
    String? contactPersonName,
    String? address,
    String? notes,
    Map<String, String>? extraFields,
    String? imagePath,
    DateTime? scannedAt,
    bool? isFavorite,
  }) {
    return LeadModel(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      mailId: mailId ?? this.mailId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      extraFields: extraFields ?? this.extraFields,
      imagePath: imagePath ?? this.imagePath,
      scannedAt: scannedAt ?? this.scannedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Returns true if all lead contact and company fields and extra fields are blank.
  bool get isEmpty =>
      companyName.trim().isEmpty &&
      mailId.trim().isEmpty &&
      phoneNumber.trim().isEmpty &&
      contactPersonName.trim().isEmpty &&
      address.trim().isEmpty &&
      notes.trim().isEmpty &&
      extraFields.isEmpty;

  /// Returns true if at least one key field contains text.
  bool get isNotEmpty => !isEmpty;

  @override
  String toString() {
    return 'LeadModel(id: $id, companyName: $companyName, mailId: $mailId, phoneNumber: $phoneNumber, contactPersonName: $contactPersonName, address: $address, extraFields: $extraFields, scannedAt: $scannedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeadModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
