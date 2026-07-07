class EventConfig {
  const EventConfig._();

  static const name = 'NSE International Conference';
  static const year = '2026';
  static const shortName = "NSE '26";
  static const tagline =
      'Engineering Innovation for Enhanced Security and Sustainable National Development';
  static const dates = '30 November – 4 December 2026';
  static final DateTime startDate = DateTime(2026, 11, 30);
  static final DateTime endDate = DateTime(2026, 12, 4, 23, 59);

  /// Whole days until the conference starts. 0 or negative once it is live/past.
  static int get daysToGo {
    final now = DateTime.now();
    return DateTime(startDate.year, startDate.month, startDate.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }

  /// Short label for the home hero countdown chip.
  static String get countdownLabel {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 'See you next year';
    final days = daysToGo;
    if (days <= 0) return 'Happening now';
    if (days == 1) return 'Starts tomorrow';
    return '$days days to go';
  }

  static const venueName = 'International Conference Centre';
  static const venueAddress = 'Maiduguri, Borno State, Nigeria';
  static const venueLatitude = 11.8333;
  static const venueLongitude = 13.15;

  static const wifiSsid = 'NSE-Conference-2026';
  static const wifiPassword = 'engineers2026';
  static const primaryHotline = '+2348009876543';
  static const logoUrl =
      'https://nse.org.ng/wp-content/uploads/2021/09/NSEHeaderReal.png';
  static const officialSite = 'https://nse.org.ng/';
}
