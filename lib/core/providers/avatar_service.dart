/// Avatar Service - Generates custom avatars using DiceBear API
///
/// DiceBear is a free avatar service. For more styles, visit: https://www.dicebear.com
class AvatarService {
  /// Generate a DiceBear avatar URL from a user's name
  ///
  /// Example: "John Doe" -> "https://api.dicebear.com/9.x/initials/svg?seed=JohnDoe"
  static String generateAvatarUrl(String userName) {
    // Remove spaces and use the name as seed
    final seed = userName.replaceAll(' ', '');
    return 'https://api.dicebear.com/9.x/initials/svg?seed=$seed&backgroundColor=0066CC,00CC66,FF3333&textColor=ffffff';
  }

  /// Alternative: Avataaars style (more fun, cartoon-like)
  static String generateAvataaarsUrl(String userName) {
    final seed = userName.replaceAll(' ', '');
    return 'https://api.dicebear.com/9.x/avataaars/svg?seed=$seed&scale=90';
  }

  /// Alternative: Pixel style avatars
  static String generatePixelUrl(String userName) {
    final seed = userName.replaceAll(' ', '');
    return 'https://api.dicebear.com/9.x/pixel-art/svg?seed=$seed&scale=90';
  }
}
