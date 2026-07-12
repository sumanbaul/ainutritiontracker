import 'dart:typed_data';

const maxMealImageBytes = 5000000;

String? validateMealImage({
  required String path,
  required int bytes,
  required Uint8List header,
}) {
  if (bytes > maxMealImageBytes) return 'Choose an image smaller than 5 MB.';
  final extension = path.split('.').last.toLowerCase();
  final typeIsValid = switch (extension) {
    'jpg' || 'jpeg' => _isJpeg(header),
    'png' => _isPng(header),
    'webp' => _isWebp(header),
    _ => false,
  };
  return typeIsValid ? null : 'Use a valid JPEG, PNG, or WebP image.';
}

bool _isJpeg(Uint8List bytes) =>
    bytes.length >= 3 &&
    bytes[0] == 0xff &&
    bytes[1] == 0xd8 &&
    bytes[2] == 0xff;
bool _isPng(Uint8List bytes) =>
    bytes.length >= 8 &&
    bytes[0] == 137 &&
    bytes[1] == 80 &&
    bytes[2] == 78 &&
    bytes[3] == 71 &&
    bytes[4] == 13 &&
    bytes[5] == 10 &&
    bytes[6] == 26 &&
    bytes[7] == 10;
bool _isWebp(Uint8List bytes) =>
    bytes.length >= 12 &&
    String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
    String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP';
