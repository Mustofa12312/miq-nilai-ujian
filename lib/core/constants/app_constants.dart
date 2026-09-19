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
  // Logika baru: berdasarkan nilai final langsung (0-100)
  // Total = 100 - semua potongan, tidak ada pembagian dengan maxScore lagi
  static String calculateGrade(double totalScore) {
    if (totalScore >= 90) return 'Mumtaz';
    if (totalScore >= 80) return 'Jayyid Jiddan';
    if (totalScore >= 70) return 'Jayyid';
    if (totalScore >= 60) return 'Maqbul';
    return "I'adah";
  }

  static double calculatePercentage(double totalScore, double maxScore) =>
      maxScore > 0 ? (totalScore / maxScore) * 100 : 0;
}
