class AppConstants {
  static const String appName = 'SonicVault';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Your music. Your covers. Your lyrics. Your rules.';

  static const List<String> supportedAudioFormats = [
    '.mp3', '.flac', '.wav', '.ogg', '.aac', '.m4a', '.opus',
  ];

  static const List<String> supportedImageFormats = [
    '.jpg', '.jpeg', '.png', '.webp',
  ];

  static const List<String> supportedLyricFormats = ['.lrc'];

  // Database
  static const String databaseName = 'sonic_vault.db';
  static const int databaseVersion = 1;

  // Cover art
  static const int coverArtSize = 500;
  static const int coverArtThumbnailSize = 128;
  static const double coverArtAspectRatio = 1.0;
}
