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
}
