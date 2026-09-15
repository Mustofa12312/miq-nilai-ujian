class AppConstants {
  // ── App Info ──────────────────────────────────────────────────────────────
  static const String appName = 'MIQ Assessment';
  static const String appVersion = '1.0.0';
  static const String institutionName = "Madrasah Ilmu Al-Qur'an";

  // ── Scoring Category Names ─────────────────────────────────────────────────
  // Nama kategori ini harus sesuai dengan nilai kolom `category` di tabel `criteria`
  static const String categoryTajwid = 'TAJWID';
  static const String categoryFasohah = 'FASOHAH';

  // ── Grade Calculation ──────────────────────────────────────────────────────
  // Berdasarkan PERSENTASE dari total skor terhadap maksimum (konsisten dengan web)
  static String calculateGrade(double totalScore, double maxScore) {
    if (maxScore <= 0) return "I'adah";
    final pct = (totalScore / maxScore) * 100;
    if (pct >= 90) return 'Mumtaz';
    if (pct >= 80) return 'Jayyid Jiddan';
    if (pct >= 70) return 'Jayyid';
    if (pct >= 60) return 'Maqbul';
    return "I'adah";
  }

  static double calculatePercentage(double totalScore, double maxScore) =>
      maxScore > 0 ? (totalScore / maxScore) * 100 : 0;
}
