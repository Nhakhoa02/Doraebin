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
      CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        emoji TEXT,
        color_hex TEXT
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL UNIQUE,
        category_id TEXT,
        added_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // Always synchronize categories to ensure updates propagate
    _insertDefaultCategories();

    // Add some default words if empty
    final ResultSet results = _db.select('SELECT COUNT(*) as count FROM words');
    if (results.first['count'] == 0) {
      _insertDefaultWords();
    }
  }

  void _insertDefaultCategories() {
    final categories = [
      ['gia_dinh', 'Gia đình', '👨‍👩‍👧‍👦', '#FF5722'],
      ['co_the', 'Cơ thể', '👃', '#E91E63'],
      ['mau_sac', 'Màu sắc', '🌈', '#9C27B0'],
      ['so_dem', 'Số đếm', '🔢', '#673AB7'],
      ['dong_vat', 'Động vật', '🐶', '#FF9800'],
      ['con_trung', 'Côn trùng', '🐛', '#4CAF50'],
      ['hoa', 'Hoa', '🌻', '#8BC34A'],
      ['cay_coi', 'Cây cối', '🌳', '#8BC34A'],
      ['trai_cay', 'Trái cây', '🍎', '#F44336'],
      ['rau_cu', 'Rau củ', '🥕', '#F44336'],
      ['mon_an', 'Món ăn', '🍕', '#FFC107'],
      ['nuoc_uong', 'Nước uống', '🥤', '#FFC107'],
      ['quan_ao', 'Quần áo', '👕', '#3F51B5'],
      ['do_choi', 'Đồ chơi', '🧸', '#00BCD4'],
      ['truong_hoc', 'Trường học', '🎒', '#795548'],
      ['giao_thong', 'Giao thông', '🚗', '#607D8B'],
      ['nha_cua', 'Nhà cửa', '🏠', '#009688'],
      ['bien', 'Biển', '🌊', '#2196F3'],
      ['thoi_tiet', 'Thời tiết', '☀️', '#FFEB3B'],
      ['cam_xuc', 'Cảm xúc', '😊', '#FF4081'],
      ['nghe_nghiep', 'Nghề nghiệp', '👩‍⚕️', '#9E9E9E'],
      ['alphabet', 'Bảng chữ cái', '🔤', '#03A9F4'],
      ['am_tiet', 'Âm tiết', '🔤', '#03A9F4'],
      ['custom', 'Khác', '✨', '#9E9E9E'],
    ];

    // Clean up old renamed table IDs to avoid cluttering the UI
    final oldIds = ['con_trung_bo_sat', 'hoa_cay_coi', 'trai_cay_rau_cu', 'mon_an_nuoc_uong', 'quan_ao_do_dung', 'bien_khai', 'alphabet_am_tiet'];
    for (var id in oldIds) {
      try {
        _db.execute('DELETE FROM categories WHERE id = ?', [id]);
      } catch (_) {}
    }

    final stmt = _db.prepare('INSERT OR REPLACE INTO categories (id, title, emoji, color_hex) VALUES (?, ?, ?, ?)');
    for (var cat in categories) {
      stmt.execute(cat);
    }
    stmt.dispose();
  }

  void _insertDefaultWords() {
    final defaults = [
      ['ba', 'gia_dinh'],
      ['mẹ', 'gia_dinh'],
      ['bé', 'gia_dinh'],
      ['cá', 'dong_vat'],
      ['gà', 'dong_vat'],
      ['chó', 'dong_vat'],
      ['mèo', 'dong_vat'],
      ['nhà', 'nha_cua'],
      ['trường', 'truong_hoc'],
      ['học', 'truong_hoc'],
    ];
    final stmt = _db.prepare('INSERT INTO words (text, category_id) VALUES (?, ?)');
    for (var word in defaults) {
      stmt.execute(word);
    }
    stmt.dispose();
  }

  List<Map<String, dynamic>> getAllCategories() {
    final ResultSet results = _db.select('SELECT * FROM categories');
    return results.map((row) => {
      'id': row['id'],
      'title': row['title'],
      'emoji': row['emoji'],
      'color_hex': row['color_hex'],
    }).toList();
  }

  List<Map<String, dynamic>> getAllWords() {
    final ResultSet results = _db.select('SELECT * FROM words ORDER BY added_at DESC');
    return results.map((row) => {
      'id': row['id'],
      'text': row['text'],
      'category_id': row['category_id'],
      'added_at': row['added_at'],
    }).toList();
  }

  void addWord(String text, {String categoryId = 'custom'}) {
    try {
      final stmt = _db.prepare('INSERT INTO words (text, category_id) VALUES (?, ?)');
      stmt.execute([text, categoryId]);
      stmt.dispose();
    } catch (e) {
      // Ignore duplicates or handle error
      print('Error adding word: $e');
    }
  }

  List<Map<String, dynamic>> getWordsByCategory(String categoryId) {
    final ResultSet results = _db.select('SELECT * FROM words WHERE category_id = ?', [categoryId]);
    return results.map((row) => {
      'id': row['id'],
      'text': row['text'],
      'category_id': row['category_id'],
      'added_at': row['added_at'],
    }).toList();
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
