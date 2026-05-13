import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import '../../features/home/domain/category_assets.dart';

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

    // Update words table with ON DELETE CASCADE to handle orphaned words
    _db.execute('''
      CREATE TABLE IF NOT EXISTS words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL UNIQUE,
        category_id TEXT,
        image_url TEXT,
        added_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // Migration: Add image_url column if it doesn't exist
    try {
      _db.execute('ALTER TABLE words ADD COLUMN image_url TEXT');
    } catch (_) {
      // Column already exists or table doesn't exist yet
    }

    // Always synchronize categories to ensure updates propagate
    _insertDefaultCategories();

    // Always synchronize default words
    _insertDefaultWords();
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
      // ['cay_coi', 'Cây cối', '🌳', '#8BC34A'],
      // ['trai_cay', 'Trái cây', '🍎', '#F44336'],
      // ['rau_cu', 'Rau củ', '🥕', '#F44336'],
      ['mon_an',  'Đồ ăn', '🍕', '#FFC107'],
      ['nuoc_uong', 'Nước uống', '🥤', '#FFC107'],
      ['quan_ao', 'Quần áo', '👕', '#3F51B5'],
      ['do_choi', 'Đồ chơi', '🧸', '#00BCD4'],
      ['truong_hoc', 'Trường học', '🎒', '#795548'],
      // ['giao_thong', 'Giao thông', '🚗', '#607D8B'],
      ['bien', 'Biển', '🌊', '#2196F3'],
      // ['thoi_tiet', 'Thời tiết', '☀️', '#FFEB3B'],
      // ['cam_xuc', 'Cảm xúc', '😊', '#FF4081'],
      // ['nghe_nghiep', 'Nghề nghiệp', '👩‍⚕️', '#9E9E9E'],
      ['alphabet', 'Bảng chữ cái', '🔤', '#03A9F4'],
    ];

    // Remove any category NOT in the current list (Pruning)
    final currentIds = categories.map((c) => "'${c[0]}'").join(',');
    _db.execute('DELETE FROM categories WHERE id NOT IN ($currentIds)');

    final stmt = _db.prepare('INSERT OR REPLACE INTO categories (id, title, emoji, color_hex) VALUES (?, ?, ?, ?)');
    for (var cat in categories) {
      stmt.execute(cat);
    }
    stmt.dispose();
  }

  void _insertDefaultWords() {
    final Map<String, List<String>> categoryWords = {
      'gia_dinh': [
        //people 
        'bố', 'mẹ', 'ông', 'bà', 'anh trai', 'chị gái', 'em trai', 'em gái',
        // items
        'ngôi nhà', 'cửa sổ', 'hàng rào',
        'sân nhà', 'phòng khách', 'phòng ngủ', 'nhà bếp', 'nhà vệ sinh',
        'bàn', 'ghế', 'giường ngủ', 'tủ quần áo', 'tủ lạnh',
        'bóng đèn', 'quạt', 'gương', 'ti vi',
        'bếp', 'chén', 'tô', 'ly', 'muỗng', 'nĩa', 'đũa'
      ],
      'co_the': [
        'đầu', 'tóc', 'mặt', 'mắt', 'mũi', 'miệng', 'tai', 'môi',
        'cổ', 'vai', 'bàn tay', 'bàn chân', 
        'ngón tay', 'ngón chân', 
        'bụng', 'lưng', 
        'lưỡi', 'răng', 
        'đầu gối', 'khuỷu tay'
      ],
      'mau_sac': [
        'màu đỏ', 'màu cam', 'màu vàng', 'màu xanh lá', 'màu xanh dương', 
        'màu tím', 'màu hồng', 'màu nâu', 'màu đen', 'màu trắng', 
        'màu xám'
      ],
      'so_dem': [
        'không', 'một', 'hai', 'ba', 'bốn', 'năm',
        'sáu', 'bảy', 'tám', 'chín', 'mười',
      ],
      'dong_vat': [
        'con chó', 'con mèo', 'con chuột', 'con thỏ',
        'con gà', 'con vịt', 'con bò', 'con heo', 'con cừu', 'con ngựa',
        'con voi', 'con hổ', 'con sư tử', 'con gấu', 'con khỉ', 'con cáo', 'con hươu', 
        'con sóc', 'con cá', 'con chim',
        'con ếch', 'con rùa',
      ],
      'con_trung': [
        'con bướm', 'con ong', 'con kiến', 'con ruồi', 'con muỗi', 
        'con nhện', 'con sâu', 
        'con chuồn chuồn', 'bọ ngựa', 
        've sầu'
      ],
      'hoa': [
        'hoa hồng', 'hoa hướng dương', 'hoa cúc', 'hoa lan', 
        'hoa ly', 'hoa sen', 'hoa đào', 'hoa mai', 'hoa loa kèn',
        'hoa dâm bụt'
      ],
      'mon_an': [
        'cơm', 'phở', 'bún', 'mì', 'bánh mì', 
        'bánh chưng', 'bánh tét',
        'chả giò', 
        'thịt gà', 'thịt bò', 'thịt heo', 
        'trứng', 'súp',
        'kem', 'bánh quy', 'kẹo'
      ],
      'nuoc_uong': [
        'nước suối', 
        'sữa tươi', 'sữa chua', 
        'nước cam', 'nước táo', 'nước dừa', 
        'nước ngọt', 
        'trà sữa', 'nước ép', 'sinh tố', 
        'nước chanh', 'nước mía'
      ],
      'quan_ao': [
        'áo', 'quần', 'váy', 'đầm', 'áo khoác', 
        'áo sơ mi', 'áo thun', 
        'giày', 'dép', 'vớ', 'nón', 'khăn quàng cổ'
      ],
      'do_choi': [
        'bong bóng', 'búp bê', 'gấu bông', 'xếp hình', 
        'cầu trượt', 'xích đu', 'diều', 'con quay'
      ],
      'truong_hoc': [
        'trường học', 'lớp học', 'bảng đen', 'phấn', 
        'sách', 'vở', 'bút chì', 'bút bi', 
        'thước kẻ', 'cặp sách', 
        'ghế học', 'bàn học', 
        'cô giáo', 'thầy giáo', 
        'bạn bè', 'bài tập', 'tiết học', 
        'cổng trường', 'sân trường'
      ],
      'bien': [
        'bãi biển', 'cát', 'sóng biển', 
        'cá heo', 'cá mập', 'sao biển', 
        'con sò', 'con cua', 
        'rùa biển', 'con mực', 'con bạch tuộc', 
        'cá voi', 'cá ngựa', 
        'hải đăng'
      ],
      'alphabet': [
        'a', 'ă', 'â', 'b', 'c', 'd', 'đ', 'e', 'ê', 
        'g', 'h', 'i', 'k', 'l', 'm', 'n', 'o', 'ô', 'ơ',
        'p', 'q', 'r', 's', 't', 'u', 'ư', 'v', 'x', 'y'
      ],
    };

    final stmt = _db.prepare('INSERT OR REPLACE INTO words (text, category_id, image_url) VALUES (?, ?, ?)');
    
    // Track all current default word texts to prune old ones
    final List<String> currentWordTexts = [];

    categoryWords.forEach((categoryId, words) {
      for (var word in words) {
        currentWordTexts.add(word);
        final imageUrl = _resolveImageUrl(categoryId, word);
        stmt.execute([word, categoryId, imageUrl]);
      }
    });

    stmt.dispose();

    // Prune old words that are no longer in the default list 
    // but belong to one of the default categories.
    final defaultCategoryIds = categoryWords.keys.map((id) => "'$id'").join(',');
    final validWordTexts = currentWordTexts.map((t) => "'${t.replaceAll("'", "''")}'").join(',');
    
    _db.execute('''
      DELETE FROM words 
      WHERE category_id IN ($defaultCategoryIds) 
      AND text NOT IN ($validWordTexts)
    ''');
  }

  String? _resolveImageUrl(String categoryId, String word) {
    return CategoryAssets.getWordAsset(categoryId, word);
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
      'image_url': row['image_url'],
      'added_at': row['added_at'],
    }).toList();
  }

  void addWord(String text, {String categoryId = 'custom', String? imageUrl}) {
    try {
      final stmt = _db.prepare('INSERT INTO words (text, category_id, image_url) VALUES (?, ?, ?)');
      stmt.execute([text, categoryId, imageUrl]);
      stmt.dispose();
    } catch (e) {
      // Update image_url if word already exists
      _db.execute('UPDATE words SET image_url = ? WHERE text = ?', [imageUrl, text]);
    }
  }

  List<Map<String, dynamic>> getWordsByCategory(String categoryId) {
    final ResultSet results = _db.select('SELECT * FROM words WHERE category_id = ?', [categoryId]);
    return results.map((row) => {
      'id': row['id'],
      'text': row['text'],
      'category_id': row['category_id'],
      'image_url': row['image_url'],
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
