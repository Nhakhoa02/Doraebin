import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class DatabaseService {
  late Database _db;

  Future<void> init() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'doraebin.db');
    
    _db = sqlite3.open(dbPath);
    
    _createTables();
  }

  void _createTables() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL UNIQUE,
        category TEXT,
        added_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Add some default words if empty
    final ResultSet results = _db.select('SELECT COUNT(*) as count FROM words');
    if (results.first['count'] == 0) {
      _insertDefaultWords();
    }
  }

  void _insertDefaultWords() {
    final defaults = [
      'ba', 'mẹ', 'bé', 'cá', 'gà', 'chó', 'mèo', 'nhà', 'trường', 'học'
    ];
    final stmt = _db.prepare('INSERT INTO words (text, category) VALUES (?, ?)');
    for (var word in defaults) {
      stmt.execute([word, 'basic']);
    }
    stmt.dispose();
  }

  List<Map<String, dynamic>> getAllWords() {
    final ResultSet results = _db.select('SELECT * FROM words ORDER BY added_at DESC');
    return results.map((row) => {
      'id': row['id'],
      'text': row['text'],
      'category': row['category'],
      'added_at': row['added_at'],
    }).toList();
  }

  void addWord(String text, {String category = 'custom'}) {
    try {
      final stmt = _db.prepare('INSERT INTO words (text, category) VALUES (?, ?)');
      stmt.execute([text, category]);
      stmt.dispose();
    } catch (e) {
      // Ignore duplicates or handle error
      print('Error adding word: $e');
    }
  }

  void deleteWord(int id) {
    final stmt = _db.prepare('DELETE FROM words WHERE id = ?');
    stmt.execute([id]);
    stmt.dispose();
  }

  void dispose() {
    _db.dispose();
  }
}
