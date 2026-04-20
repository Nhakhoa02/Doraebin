/// Static registry mapping category IDs to their Lottie animation asset paths.
///
/// Categories without an entry here will fall back to their emoji icon.
/// As you add more .lottie files to assets/animations/, register them here.
class CategoryAssets {
  CategoryAssets._();

  /// Map of category_id → asset path for Lottie icons.
  static const Map<String, String> lottieIcons = {
    'gia_dinh': 'assets/animations/family.lottie',
    // Add more as you get assets:
    // 'dong_vat': 'assets/animations/animals.lottie',
    // 'trai_cay': 'assets/animations/fruits.lottie',
  };

  /// Returns the Lottie asset path for a category, or null if none exists.
  static String? getLottieAsset(String categoryId) {
    return lottieIcons[categoryId];
  }

  /// Whether a category has a Lottie icon available.
  static bool hasLottieIcon(String categoryId) {
    return lottieIcons.containsKey(categoryId);
  }
}
