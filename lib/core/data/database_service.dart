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

    // Update words table with ON DELETE CASCADE to handle orphaned words
    _db.execute('''
      CREATE TABLE IF NOT EXISTS words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL UNIQUE,
        category_id TEXT,
        added_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

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
      ['cay_coi', 'Cây cối', '🌳', '#8BC34A'],
      ['trai_cay', 'Trái cây', '🍎', '#F44336'],
      ['rau_cu', 'Rau củ', '🥕', '#F44336'],
      ['mon_an',  'Đồ ăn', '🍕', '#FFC107'],
      ['nuoc_uong', 'Nước uống', '🥤', '#FFC107'],
      ['quan_ao', 'Quần áo', '👕', '#3F51B5'],
      ['do_choi', 'Đồ chơi', '🧸', '#00BCD4'],
      ['truong_hoc', 'Trường học', '🎒', '#795548'],
      ['giao_thong', 'Giao thông', '🚗', '#607D8B'],
      ['bien', 'Biển', '🌊', '#2196F3'],
      ['thoi_tiet', 'Thời tiết', '☀️', '#FFEB3B'],
      ['cam_xuc', 'Cảm xúc', '😊', '#FF4081'],
      ['nghe_nghiep', 'Nghề nghiệp', '👩‍⚕️', '#9E9E9E'],
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
        'bố', 'mẹ', 'ông', 'bà', 'anh', 'chị', 'em',
        // items
        'ngôi nhà', 'cửa sổ', 'hàng rào',
        'sân nhà', 'phòng khách', 'phòng ngủ', 'nhà bếp', 'nhà vệ sinh',
        'bàn', 'ghế', 'giường', 'tủ', 'tủ quần áo', 'tủ lạnh',
        'đèn', 'bóng đèn', 'quạt', 'gương', 'ti vi',
        'bếp', 'chén', 'bát', 'muỗng'
      ],
      'co_the': [
        'đầu', 'tóc', 'mặt', 'mắt', 'mũi', 'miệng', 'tai', 
        'cổ', 'vai', 'bàn tay', 'bàn chân', 
        'ngón tay', 'ngón chân', 
        'bụng', 'lưng', 
        'da', 'lưỡi', 'răng', 
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
        'con sóc', 'cá heo', 'chim cánh cụt',
        'con cá', 'con chim', 'con ếch', 'con rùa', 'cá sấu'
      ],
      'con_trung': [
        'con bướm', 'con ong', 'con kiến', 'con ruồi', 'con muỗi', 
        'con nhện', 'con bọ cánh cứng', 'con sâu', 
        'con chuồn chuồn', 'bọ xít', 'bọ ngựa', 
        've sầu', 'bọ hung'
      ],
      'hoa': [
        'hoa hồng', 'hoa hướng dương', 'hoa cúc', 'hoa lan', 
        'hoa ly', 'hoa sen', 'hoa đào', 'hoa mai', 'hoa loa kèn',
        'hoa dâm bụt', 'hoa nhài', 'hoa oải hương', 'hoa cẩm tú cầu', 'hoa mẫu đơn'
      ],
      'cay_coi': [
        'cây tre', 'cây chuối', 'cây xoài', 'cây mít', 'cây ổi', 
        'cây bàng', 'cây phượng', 'cây thông', 'cây cau', 'cây dừa',
        'cây me', 'cây khế', 'cây sung', 'cây đa'
      ],
      'trai_cay': [
        'quả táo', 'quả cam', 'quả chuối', 'quả nho', 'quả dâu', 
        'quả xoài', 'quả dưa hấu', 'quả dứa', 'quả đu đủ', 'quả lê',
        'quả bơ', 'quả chanh', 'quả mận', 'quả thanh long', 'quả ổi', 'quả dừa', 'quả bưởi'
      ],
      'rau_cu': [
        'củ cà rốt', 'quả cà chua', 'củ khoai tây', 'bắp cải',
        'quả bí đỏ', 'quả bí đao', 'quả dưa chuột', 'quả ớt', 'củ hành tây',
        'củ khoai lang', 'quả mướp',
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
        'nước', 'nước lọc', 'nước suối', 
        'sữa', 'sữa tươi', 'sữa chua', 
        'nước cam', 'nước táo', 'nước dừa', 
        'nước ngọt', 
        'trà sữa', 'nước ép', 'sinh tố', 
        'nước chanh', 'nước mía'
      ],
      'quan_ao': [
        'áo', 'quần', 'váy', 'đầm', 'áo khoác', 
        'áo sơ mi', 'áo thun', 
        'giày', 'dép', 'vớ', 'mũ', 'nón', 'khăn quàng cổ'
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
      'giao_thong': [
        'xe máy', 'xe đạp', 'xe hơi', 'xe buýt', 
        'xe tải', 'xe lửa', 'tàu lửa', 
        'máy bay', 'thuyền', 'xuồng', 
        'xe cứu thương', 'xe cứu hỏa', 'vỉa hè',
        'đèn giao thông', 'đường phố', 
        'cầu', 'sân bay'
      ],
      'bien': [
        // Basic sea & beach words
        'bãi biển', 'cát', 'sóng biển', 
        'nước biển',

        // Sea creatures kids love
        'cá heo', 'cá mập', 'sao biển', 'ốc biển', 
        'sò', 'cua', 
        'rùa biển', 'bạch tuộc', 'mực', 
        'cá voi', 'cá heo', 'cá ngựa', 

        // Others
        'hải đăng'
      ],
      'thoi_tiet': [
        'mặt trời', 'mặt trăng', 'nắng', 'đám mây', 'mưa', 'cầu vồng', 
        'gió', 'bão', 'sương mù', 'tuyết'
      ],
      'cam_xuc': [
        'vui', 'buồn', 'giận', 'sợ hãi', 'ngạc nhiên', 
        'hạnh phúc', 'thích', 'yêu', 'ghét', 
        'mệt mỏi', 'đói bụng', 'khát nước', 
        'cười', 'khóc', 'xấu hổ', 'tự hào',
      ],
      'nghe_nghiep': [
        'bác sĩ', 'y tá', 'thầy giáo', 'cô giáo',
        'cảnh sát', 'lính cứu hỏa', 'đầu bếp',
        'nông dân', 'kỹ sư', 
        'ca sĩ', 'diễn viên', 'hoạ sĩ', 
        'phi công', 'tài xế', 'người bán hàng'
      ],
      'alphabet': [
        'a', 'ă', 'â', 'b', 'c', 'd', 'đ', 'e', 'ê', 
        'g', 'h', 'i', 'k', 'l', 'm', 'n', 'o', 'ô', 'ơ',
        'p', 'q', 'r', 's', 't', 'u', 'ư', 'v', 'x', 'y'
      ],
    };

    final stmt = _db.prepare('INSERT OR IGNORE INTO words (text, category_id) VALUES (?, ?)');
    
    categoryWords.forEach((categoryId, words) {
      for (var word in words) {
        stmt.execute([word, categoryId]);
      }
    });

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
