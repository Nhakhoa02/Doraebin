import '../lib/features/spelling/domain/vi_spelling.dart';

void main() {
  final testWords = [
    "Ba thương con",
  ];

  print('--- KẾT QUẢ KIỂM TRA ĐÁNH VẦN ---\n');

  for (final word in testWords) {
    final result = getSpellingForText(word);
    print("Results: ${result}");
    // print('Từ: "${result.original}"');
    // print('  - Đánh vần (Chữ): ${result.spellString}');
    // print('  - Đánh vần (TTS):   ${result.ttsString}');
    // print('  - Phân tích: Initial: ${result.initial}, Nucleus: ${result.nucleus}, Ending: ${result.ending}, Tone: ${result.tone}');
    print('-' * 40);
  }
}
