/// Base class for all domain and service failures in the application.
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

/// Failure occurring during image acquisition or ML Kit OCR inference.
class OcrFailure extends Failure {
  const OcrFailure(super.message);
}

/// Failure occurring during heuristic rule extraction or AI parsing.
class ParseFailure extends Failure {
  const ParseFailure(super.message);
}

/// Failure occurring during local storage operations.
class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

/// Failure occurring during Gemini Cloud API integration.
class ApiFailure extends Failure {
  final int? statusCode;
  const ApiFailure(super.message, {this.statusCode});
}
