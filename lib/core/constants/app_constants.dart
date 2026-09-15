import '../../../shared/models/criteria_model.dart';
import '../../../shared/models/assignment_model.dart';
import '../../../shared/models/student_model.dart';
import '../../../shared/models/user_model.dart';

class AppConstants {
  // ── App Info ──────────────────────────────────────────────────────────────
  static const String appName = 'MIQ Assessment';
  static const String appVersion = '1.0.0';
  static const String institutionName = 'Madrasah Ilmu Al-Qur\'an';

  // ── Scoring Criteria (from PRD) ───────────────────────────────────────────
  static const String categoryTajwid = 'TAJWID';
  static const String categoryFasohah = 'FASOHAH';

  static final List<CriteriaModel> allCriteria = [
    // TAJWID
    CriteriaModel(
      id: 1,
      category: categoryTajwid,
      name: 'Makhroj',
      defaultScore: 30,
      deduction: 3,
      sortOrder: 1,
    ),
    CriteriaModel(
      id: 2,
      category: categoryTajwid,
      name: 'Sifat',
      defaultScore: 20,
      deduction: 2,
      sortOrder: 2,
    ),
    CriteriaModel(
      id: 3,
      category: categoryTajwid,
      name: 'Ahkam Huruf',
      defaultScore: 10,
      deduction: 1,
      sortOrder: 3,
    ),
    CriteriaModel(
      id: 4,
      category: categoryTajwid,
      name: 'Ahkam Mad & Qoshr',
      defaultScore: 10,
      deduction: 1,
      sortOrder: 4,
    ),
    // FASOHAH
    CriteriaModel(
      id: 5,
      category: categoryFasohah,
      name: 'Waqof Ibtida\'',
      defaultScore: 20,
      deduction: 2,
      sortOrder: 5,
    ),
    CriteriaModel(
      id: 6,
      category: categoryFasohah,
      name: 'Muro\'atul Huruf',
      defaultScore: 20,
      deduction: 2,
      sortOrder: 6,
    ),
    CriteriaModel(
      id: 7,
      category: categoryFasohah,
      name: 'Tawallud',
      defaultScore: 10,
      deduction: 1,
      sortOrder: 7,
    ),
    CriteriaModel(
      id: 8,
      category: categoryFasohah,
      name: 'Miring',
      defaultScore: 10,
      deduction: 1,
      sortOrder: 8,
    ),
    CriteriaModel(
      id: 9,
      category: categoryFasohah,
      name: 'Kelancaran',
      defaultScore: 10,
      deduction: 1,
      sortOrder: 9,
    ),
  ];

  static double get maxTotalScore =>
      allCriteria.fold(0, (sum, c) => sum + c.defaultScore);

  // ── Grade Calculation ──────────────────────────────────────────────────────
  static String calculateGrade(double totalScore) {
    final pct = (totalScore / maxTotalScore) * 100;
    if (pct >= 90) return 'Mumtaz';
    if (pct >= 80) return 'Jayyid Jiddan';
    if (pct >= 70) return 'Jayyid';
    if (pct >= 60) return 'Maqbul';
    return 'I\'adah';
  }

  static double calculatePercentage(double totalScore) =>
      (totalScore / maxTotalScore) * 100;

  // ── Mock Data ─────────────────────────────────────────────────────────────
  static final UserModel mockExaminer = UserModel(
    id: 'usr-001',
    fullName: 'Ust. Ahmad Fauzi',
    email: 'ahmad@miq.sch.id',
    role: UserRole.examiner,
    status: true,
  );

  static final List<AssignmentModel> mockAssignments = [
    AssignmentModel(
      id: 1,
      examinerId: 'usr-001',
      periodId: 1,
      periodName: 'Semester Genap 2027',
      levelId: 2,
      levelName: 'Al-Qur\'an II',
      classId: 4,
      className: 'B4',
      totalStudents: 34,
      scoredStudents: 18,
    ),
    AssignmentModel(
      id: 2,
      examinerId: 'usr-001',
      periodId: 1,
      periodName: 'Semester Genap 2027',
      levelId: 2,
      levelName: 'Al-Qur\'an II',
      classId: 5,
      className: 'B5',
      totalStudents: 31,
      scoredStudents: 5,
    ),
    AssignmentModel(
      id: 3,
      examinerId: 'usr-001',
      periodId: 1,
      periodName: 'Semester Genap 2027',
      levelId: 1,
      levelName: 'Al-Qur\'an I',
      classId: 3,
      className: 'A3',
      totalStudents: 30,
      scoredStudents: 30,
    ),
  ];

  static List<StudentModel> mockStudentsForClass(int classId) {
    final names4 = [
      'Ahmad Mubarok',
      'Abdullah Faris',
      'Abdurrahman Wahid',
      'Bilal Maulana',
      'Daud Ar-Rasyid',
      'Fadhil Hakim',
      'Fakhri Zuhdi',
      'Hamid Mukhlis',
      'Hasan Ashari',
      'Ibrahim Nuha',
      'Ilham Akbar',
      'Iqbal Ramadhan',
      'Ismail Siddiq',
      'Khairul Amin',
      'Luthfi Azhari',
      'Muhammad Naufal',
      'Mustofa Kamal',
      'Naufal Arif',
      'Omar Farouq',
      'Qodir Rahman',
      'Raihan Akbar',
      'Rizqi Maulida',
      'Salman Alfarisi',
      'Syamsul Huda',
      'Taufiq Hidayat',
      'Umar Husain',
      'Wahyu Santoso',
      'Yahya Basri',
      'Yusuf Mubarak',
      'Zaid Habibi',
      'Zaky Mubarok',
      'Zulfan Naim',
      'Zulkifli Rahman',
      'Zulkarnain Amar',
    ];

    final names5 = [
      'Abdul Aziz',
      'Abdurrahman Saleh',
      'Ahmad Khairul',
      'Ahmad Ridwan',
      'Anas Muttaqin',
      'Arif Billah',
      'Badruzzaman',
      'Fahmi Husain',
      'Fauzan Ilmi',
      'Hafidz Mukhtar',
      'Hamzah Amir',
      'Haris Munandar',
      'Hasbi Rabbani',
      'Hilmi Arkan',
      'Ihsan Kamil',
      'Izzuddin Saif',
      'Jabir Atsir',
      'Kamil Muttaqin',
      'Lukman Hakim',
      'Mahfudz Nasir',
      'Masruhin Yusuf',
      'Miftah Faruq',
      'Mudzakir Ali',
      'Muhammad Ihsan',
      'Najib Rahman',
      'Nashiruddin',
      'Nauval Amri',
      'Nurul Haq',
      'Raffi Santoso',
      'Rauf Karim',
      'Rayhan Zahra',
    ];

    final names3 = [
      'Abdan Syakuro',
      'Afifuddin Saad',
      'Ahmad Zaki',
      'Alim Mubarok',
      'Aqil Husain',
      'Arkan Fathoni',
      'Asif Mahfudz',
      'Athif Salim',
      'Aufa Rahman',
      'Azzam Mukhtar',
      'Baha Zain',
      'Dhiya Ulhaq',
      'Faris Ardian',
      'Fathul Amin',
      'Ghufron Najib',
      'Hafiz Akmal',
      'Halim Azhar',
      'Hamdan Mufid',
      'Husain Ahmad',
      'Ilyas Murshid',
      'Imron Wahid',
      'Irfan Habibi',
      'Izzah Akbar',
      'Jabbar Falah',
      'Kamim Tholhah',
      'Khalid Harun',
      'Khozin Rosyad',
      'Lathif Karim',
      'Luqman Nur',
      'Ma\'ruf Syarif',
    ];

    List<String> names;
    int scored;
    if (classId == 4) {
      names = names4;
      scored = 18;
    } else if (classId == 5) {
      names = names5;
      scored = 5;
    } else {
      names = names3;
      scored = 30; // all scored
    }

    return List.generate(names.length, (i) {
      final isScored = i < scored;
      return StudentModel(
        id: (classId * 100) + i + 1,
        classId: classId,
        fullName: names[i],
        active: true,
        isScored: isScored,
        totalScore: isScored ? (100 + (i % 30) * 1.2) : null,
        grade: isScored
            ? calculateGrade(100 + (i % 30) * 1.2)
            : null,
      );
    });
  }
}
