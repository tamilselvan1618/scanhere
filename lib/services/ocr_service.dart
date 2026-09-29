import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Service wrapping image acquisition (camera/gallery) and Google ML Kit on-device OCR inference.
class OcrService {
  final ImagePicker _picker;
  final TextRecognizer _textRecognizer;

  OcrService({
    ImagePicker? picker,
    TextRecognizer? textRecognizer,
  })  : _picker = picker ?? ImagePicker(),
        _textRecognizer = textRecognizer ??
            TextRecognizer(script: TextRecognitionScript.latin);

  /// Picks an image from [source] (Camera or Gallery) and performs OCR text recognition.
  /// Returns a record containing the nullable picked [File] and nullable [RecognizedText].
  Future<({File? imageFile, RecognizedText? recognizedText})> captureAndRecognize(
    ImageSource source,
  ) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 92,
    );

    if (pickedFile == null) {
      return (imageFile: null, recognizedText: null);
    }

    final file = File(pickedFile.path);
    final inputImage = InputImage.fromFile(file);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    return (imageFile: file, recognizedText: recognizedText);
  }

  /// Performs direct OCR recognition on an existing [imageFile].
  Future<RecognizedText> processImageFile(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    return _textRecognizer.processImage(inputImage);
  }

  /// Alias for processImageFile
  Future<RecognizedText> recognizeFile(File imageFile) => processImageFile(imageFile);

  /// Closes the native ML Kit text recognizer pipeline.
  void dispose() {
    _textRecognizer.close();
  }
}
