/// Model representing extracted business lead details from advertisement media.
class AdLeadData {
  final String companyName;
  final String phoneNumber;
  final String companyOwner;

  const AdLeadData({
    this.companyName = '',
    this.phoneNumber = '',
    this.companyOwner = '',
  });

  /// Creates a copy of this lead with optional updated fields.
  AdLeadData copyWith({
    String? companyName,
    String? phoneNumber,
    String? companyOwner,
  }) {
    return AdLeadData(
      companyName: companyName ?? this.companyName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      companyOwner: companyOwner ?? this.companyOwner,
    );
  }

  /// Checks if all core fields are empty.
  bool get isEmpty =>
      companyName.trim().isEmpty &&
      phoneNumber.trim().isEmpty &&
      companyOwner.trim().isEmpty;

  /// Checks if at least one field has data.
  bool get isNotEmpty => !isEmpty;

  @override
  String toString() {
    return 'AdLeadData(companyName: $companyName, phoneNumber: $phoneNumber, companyOwner: $companyOwner)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdLeadData &&
        other.companyName == companyName &&
        other.phoneNumber == phoneNumber &&
        other.companyOwner == companyOwner;
  }

  @override
  int get hashCode =>
      companyName.hashCode ^ phoneNumber.hashCode ^ companyOwner.hashCode;
}
