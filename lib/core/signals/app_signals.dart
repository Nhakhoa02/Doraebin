import 'package:signals_flutter/signals_flutter.dart';
import '../data/database_service.dart';
import '../../features/spelling/domain/vi_spelling.dart';

final dbService = DatabaseService();

// Signals
final historySignal = signal<List<Map<String, dynamic>>>([]);
final currentWordSignal = signal<DecomposedSyllable?>(null);

// Actions
Future<void> initAppSignals() async {
  await dbService.init();
  refreshHistory();
}

void refreshHistory() {
  historySignal.value = dbService.getAllWords();
}

void selectWord(String text) {
  final result = decomposeVietnameseSyllable(text);
  currentWordSignal.value = result;
  
  // Add to history if not there
  dbService.addWord(text);
  refreshHistory();
}

void deleteFromHistory(int id) {
  dbService.deleteWord(id);
  refreshHistory();
}
