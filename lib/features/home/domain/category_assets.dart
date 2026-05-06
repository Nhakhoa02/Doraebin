/// Static registry mapping category IDs to their Lottie animation asset paths.
///
/// Categories without an entry here will fall back to their emoji icon.
/// As you add more .lottie files to assets/animations/, register them here.
class CategoryAssets {
  CategoryAssets._();

  /// Map of category_id → asset path for Lottie icons.
  static const Map<String, String> lottieIcons = {
    'gia_dinh': 'assets/animations/family.lottie',
    'dong_vat': 'assets/animations/animal.lottie',
    'cam_xuc': 'assets/animations/emotion.lottie',
    'bien': 'assets/animations/ocean.lottie',
    'thoi_tiet': 'assets/animations/weather.lottie',
    'con_trung': 'assets/animations/insect.lottie',
  };

  /// Map of category_id → asset path for Image icons (JPG/PNG).
  static const Map<String, String> imageIcons = {
    'alphabet': 'assets/images/alphabet.jpg',
    'mau_sac': 'assets/images/color.jpg',
    'hoa': 'assets/images/flower.jpg',
    'mon_an': 'assets/images/food.jpg',
    'trai_cay': 'assets/images/fruit.jpg',
    'so_dem': 'assets/images/number.jpg',
    'do_choi': 'assets/images/toy.jpg',
    'cay_coi': 'assets/images/tree.jpg',
  };

  /// Map of category_id → asset path for SVG icons.
  static const Map<String, String> svgIcons = {
    'co_the': 'assets/svg/body.svg',
    'quan_ao': 'assets/svg/clothes.svg',
    'nuoc_uong': 'assets/svg/drink.svg',
    'nghe_nghiep': 'assets/svg/job.svg',
    'truong_hoc': 'assets/svg/school.svg',
    'giao_thong': 'assets/svg/traffic.svg',
    'rau_cu': 'assets/svg/vegetable.svg',
  };

  /// Returns the Lottie asset path for a category, or null if none exists.
  static String? getLottieAsset(String categoryId) {
    return lottieIcons[categoryId];
  }

  /// Returns the Image asset path for a category, or null if none exists.
  static String? getImageAsset(String categoryId) {
    return imageIcons[categoryId];
  }

  /// Returns the SVG asset path for a category, or null if none exists.
  static String? getSvgAsset(String categoryId) {
    return svgIcons[categoryId];
  }

  /// Whether a category has a visual asset (Lottie, Image, or SVG).
  static bool hasVisualAsset(String categoryId) {
    return lottieIcons.containsKey(categoryId) ||
           imageIcons.containsKey(categoryId) ||
           svgIcons.containsKey(categoryId);
  }

  /// Returns the asset path for a specific word in a category.
  static String? getWordAsset(String categoryId, String word) {
    const Map<String, Map<String, String>> mapping = {
      'gia_dinh': {
        'bố': 'assets/images/gia_dinh/bố.jpg',
        'mẹ': 'assets/images/gia_dinh/mẹ.png',
        'ông': 'assets/images/gia_dinh/ông.jpg',
        'bà': 'assets/images/gia_dinh/bà.jpeg',
        'anh trai': 'assets/images/gia_dinh/anh_trai.png',
        'chị gái': 'assets/images/gia_dinh/chi_gai.png',
        'em trai': 'assets/images/gia_dinh/em_trai.png',
        'em gái': 'assets/images/gia_dinh/em_gai.png',
        'ngôi nhà': 'assets/images/gia_dinh/ngoi_nha.jfif',
        'cửa sổ': 'assets/images/gia_dinh/cua_so.jpg',
        'hàng rào': 'assets/images/gia_dinh/hang_rao.jpg',
        'sân nhà': 'assets/images/gia_dinh/sân_nhà.jfif',
        'phòng khách': 'assets/images/gia_dinh/phong_khach.jpg',
        'phòng ngủ': 'assets/images/gia_dinh/phong_ngu.jpg',
        'nhà bếp': 'assets/images/gia_dinh/nha_bep.jfif',
        'nhà vệ sinh': 'assets/images/gia_dinh/nha_ve_sinh.jfif',
        'bàn': 'assets/images/gia_dinh/ban.jfif',
        'ghế': 'assets/images/gia_dinh/ghe.png',
        'giường ngủ': 'assets/images/gia_dinh/giuong_ngu.jfif',
        'tủ quần áo': 'assets/images/gia_dinh/tu_quan_ao.jfif',
        'tủ lạnh': 'assets/images/gia_dinh/tu_lanh.jfif',
        'bóng đèn': 'assets/images/gia_dinh/bong_den.jfif',
        'quạt': 'assets/images/gia_dinh/quạt.jfif',
        'gương': 'assets/images/gia_dinh/guong.jfif',
        'ti vi': 'assets/images/gia_dinh/tivi.jfif',
        'bếp': 'assets/images/gia_dinh/bếp.jfif',
        'chén': 'assets/images/gia_dinh/chen.jfif',
        'tô': 'assets/images/gia_dinh/to.jpg',
        'ly': 'assets/images/gia_dinh/ly.jfif',
        'muỗng': 'assets/images/gia_dinh/muong.jfif',
        'nĩa': 'assets/images/gia_dinh/nĩa.jfif',
        'đũa': 'assets/images/gia_dinh/đũa.jfif',
      },
      'co_the': {
        'đầu': 'assets/images/co_the/dau.jfif',
        'tóc': 'assets/images/co_the/toc.jfif',
        'mặt': 'assets/images/co_the/mặt.jpg',
        'mắt': 'assets/images/co_the/mắt.jfif',
        'mũi': 'assets/images/co_the/mũi.jfif',
        'miệng': 'assets/images/co_the/mieng.jfif',
        'tai': 'assets/images/co_the/tai.jfif',
        'môi': 'assets/images/co_the/moi.jfif',
        'cổ': 'assets/images/co_the/cổ.jfif',
        'vai': 'assets/images/co_the/vai.png',
        'bàn tay': 'assets/images/co_the/hand.jfif',
        'bàn chân': 'assets/images/co_the/ban_chan.jfif',
        'ngón tay': 'assets/images/co_the/finger.jfif',
        'ngón chân': 'assets/images/co_the/ngon_chan.jfif',
        'bụng': 'assets/images/co_the/bung.jfif',
        'lưng': 'assets/images/co_the/lung.jfif',
        'lưỡi': 'assets/images/co_the/lưỡi.jfif',
        'răng': 'assets/images/co_the/răng.jfif',
        'đầu gối': 'assets/images/co_the/dau_goi.jfif',
        'khuỷu tay': 'assets/images/co_the/khuyu_tay.jfif',
      },
      'mau_sac': {
        'màu đỏ': 'assets/images/mau_sac/mau_do.png',
        'màu cam': 'assets/images/mau_sac/mau_cam.png',
        'màu vàng': 'assets/images/mau_sac/yellow.jfif',
        'màu xanh lá': 'assets/images/mau_sac/xanh_la.jfif',
        'màu xanh dương': 'assets/images/mau_sac/mau_xanh_duong.png',
        'màu tím': 'assets/images/mau_sac/purple.png',
        'màu hồng': 'assets/images/mau_sac/pink.png',
        'màu nâu': 'assets/images/mau_sac/mau_nau.jfif',
        'màu đen': 'assets/images/mau_sac/mau_den.png',
        'màu trắng': 'assets/images/mau_sac/mau_trang.png',
        'màu xám': 'assets/images/mau_sac/mau_xam.jpg',
      },
      'so_dem': {
        'không': 'assets/images/so_dem/khong.jfif',
        'một': 'assets/images/so_dem/mot.png',
        'hai': 'assets/images/so_dem/hai.png',
        'ba': 'assets/images/so_dem/ba.png',
        'bốn': 'assets/images/so_dem/four.jfif',
        'năm': 'assets/images/so_dem/nam.jfif',
        'sáu': 'assets/images/so_dem/sau.jfif',
        'bảy': 'assets/images/so_dem/seven.png',
        'tám': 'assets/images/so_dem/eight.jfif',
        'chín': 'assets/images/so_dem/nine.jfif',
        'mười': 'assets/images/so_dem/ten.jfif',
      },
      'dong_vat': {
        'con chó': 'assets/images/dong_vat/con_cho.jfif',
        'con mèo': 'assets/images/dong_vat/cat.jfif',
        'con chuột': 'assets/images/dong_vat/mouse.jfif',
        'con thỏ': 'assets/images/dong_vat/rabbit.jfif',
        'con vịt': 'assets/images/dong_vat/duck.jpeg',
        'con bò': 'assets/images/dong_vat/con_bo.jpg',
        'con heo': 'assets/images/dong_vat/con_heo.jpg',
        'con cừu': 'assets/images/dong_vat/con_cuu.jpg',
        'con ngựa': 'assets/images/dong_vat/con_ngua.jpg',
        'con voi': 'assets/images/dong_vat/con_voi.jpg',
        'con hổ': 'assets/images/dong_vat/con_ho.jfif',
        'con sư tử': 'assets/images/dong_vat/lion.jpg',
        'con gấu': 'assets/images/dong_vat/bear.jfif',
        'con khỉ': 'assets/images/dong_vat/con_khi.jfif',
        'con cáo': 'assets/images/dong_vat/con_cao.jfif',
        'con hươu': 'assets/images/dong_vat/con_huou.jpg',
        'con sóc': 'assets/images/dong_vat/con_soc.jfif',
        'con cá': 'assets/images/dong_vat/con_ca.jfif',
        'con chim': 'assets/images/dong_vat/con_chim.jpg',
        'con ếch': 'assets/images/dong_vat/con_ech.jfif',
        'con rùa': 'assets/images/dong_vat/con_rua.jfif',
      },
      'con_trung': {
        'con bướm': 'assets/images/con_trung/con_buom.jpg',
        'con ong': 'assets/images/con_trung/con_ong.jfif',
        'con kiến': 'assets/images/con_trung/con_kien.jfif',
        'con ruồi': 'assets/images/con_trung/con_ruoi.jpg',
        'con muỗi': 'assets/images/con_trung/con_muoi.jfif',
        'con nhện': 'assets/images/con_trung/con_nhen.jfif',
        'con sâu': 'assets/images/con_trung/con_sau.jfif',
        'con chuồn chuồn': 'assets/images/con_trung/con_chuon_chuon.png',
        'bọ ngựa': 'assets/images/con_trung/con_bo_ngua.jfif',
        've sầu': 'assets/images/con_trung/con_ve.jfif',
      },
      'hoa': {
        'hoa hồng': 'assets/images/hoa/hoa_hong.jfif',
        'hoa hướng dương': 'assets/images/hoa/hoa_huong_duong.jfif',
        'hoa cúc': 'assets/images/hoa/hoa_cuc.jfif',
        'hoa lan': 'assets/images/hoa/hoa_lan.jfif',
        'hoa ly': 'assets/images/hoa/hoa_ly.jfif',
        'hoa sen': 'assets/images/hoa/hoa_sen.jfif',
        'hoa đào': 'assets/images/hoa/hoa_dao.png',
        'hoa mai': 'assets/images/hoa/hoa_mai.jfif',
        'hoa loa kèn': 'assets/images/hoa/hoa_loa_ken.jfif',
        'hoa dâm bụt': 'assets/images/hoa/hoa_dam_but.jfif',
      },
      'mon_an': {
        'cơm': 'assets/images/mon_an/com.jpg',
        'phở': 'assets/images/mon_an/pho.webp',
        'mì': 'assets/images/mon_an/mi.webp',
        'bánh mì': 'assets/images/mon_an/banh_mi.webp',
        'bánh chưng': 'assets/images/mon_an/banh_chung.webp',
        'bánh tét': 'assets/images/mon_an/banh_tet.jpg',
        'chả giò': 'assets/images/mon_an/cha_gio.webp',
        'thịt gà': 'assets/images/mon_an/thit_ga.webp',
        'thịt bò': 'assets/images/mon_an/thit_bo.webp',
        'thịt heo': 'assets/images/mon_an/thit_heo.jpg',
        'trứng': 'assets/images/mon_an/trung.webp',
        'súp': 'assets/images/mon_an/sup.jpg',
        'kem': 'assets/images/mon_an/kem.jpg',
        'bánh quy': 'assets/images/mon_an/banh_quy.webp',
      },
      'nuoc_uong': {
        'nước suối': 'assets/images/nuoc_uong/nuoc_suoi.jpg',
        'sữa tươi': 'assets/images/nuoc_uong/sua_tuoi.jpg',
        'sữa chua': 'assets/images/nuoc_uong/sua_chua.jpg',
        'nước cam': 'assets/images/nuoc_uong/nuoc_cam.png',
        'nước táo': 'assets/images/nuoc_uong/nuoc_tao.webp',
        'nước dừa': 'assets/images/nuoc_uong/nuoc_dua.webp',
        'nước ngọt': 'assets/images/nuoc_uong/nuoc_ngot.jpg',
        'trà sữa': 'assets/images/nuoc_uong/tra_sua.jpg',
        'nước ép': 'assets/images/nuoc_uong/nuoc_ep.jpg',
        'sinh tố': 'assets/images/nuoc_uong/sinh_to.jpg',
        'nước chanh': 'assets/images/nuoc_uong/nuoc_chanh.jpg',
        'nước mía': 'assets/images/nuoc_uong/nuoc_mia.webp',
      },
      'quan_ao': {
        'quần': 'assets/images/quan_ao/quan.jpg',
        'váy': 'assets/images/quan_ao/vay.png',
        'đầm': 'assets/images/quan_ao/dam.jpg',
        'áo sơ mi': 'assets/images/quan_ao/ao_so_mi.png',
        'áo thun': 'assets/images/quan_ao/ao_thun.webp',
        'giày': 'assets/images/quan_ao/giay.jpg',
        'dép': 'assets/images/quan_ao/dep.jpg',
        'vớ': 'assets/images/quan_ao/vo.jpg',
        'mũ': 'assets/images/quan_ao/mu.jpg',
        'nón': 'assets/images/quan_ao/mu.jpg',
        'khăn quàng cổ': 'assets/images/quan_ao/khan_quang_co.webp',
      },
      'do_choi': {
        'bong bóng': 'assets/images/do_choi/bong_bong.jpg',
        'búp bê': 'assets/images/do_choi/bup_be.jpg',
        'gấu bông': 'assets/images/do_choi/gau_bong.webp',
        'xếp hình': 'assets/images/do_choi/xep_hinh.png',
        'cầu trượt': 'assets/images/do_choi/cau_truot.jpg',
        'xích đu': 'assets/images/do_choi/xich_du.png',
        'diều': 'assets/images/do_choi/dieu.webp',
        'con quay': 'assets/images/do_choi/con_quay.webp',
      },
      'truong_hoc': {
        'trường học': 'assets/images/truong_hoc/Trường học.png',
        'lớp học': 'assets/images/truong_hoc/Lớp học.jpg',
        'bảng đen': 'assets/images/truong_hoc/Bảng đen.jpg',
        'phấn': 'assets/images/truong_hoc/Phấn.jpg',
        'sách': 'assets/images/truong_hoc/Sách.webp',
        'vở': 'assets/images/truong_hoc/Vở.webp',
        'bút chì': 'assets/images/truong_hoc/Bút chì.jpg',
        'bút bi': 'assets/images/truong_hoc/Bút bi.jpg',
        'thước kẻ': 'assets/images/truong_hoc/Thước kẻ.jpg',
        'cặp sách': 'assets/images/truong_hoc/Cặp sách.jpg',
        'ghế học': 'assets/images/truong_hoc/Ghế học.jpg',
        'bàn học': 'assets/images/truong_hoc/Bàn học.jpg',
        'cô giáo': 'assets/images/truong_hoc/Cô giáo.webp',
        'thầy giáo': 'assets/images/truong_hoc/Thầy giáo.webp',
        'bạn bè': 'assets/images/truong_hoc/Bạn bè.webp',
        'bài tập': 'assets/images/truong_hoc/Bài tập.jpg',
        'tiết học': 'assets/images/truong_hoc/Tiết học.jpg',
        'cổng trường': 'assets/images/truong_hoc/Cổng trường.jpg',
        'sân trường': 'assets/images/truong_hoc/Sân trường.webp',
      }
    };

    return mapping[categoryId]?[word];
  }
}
