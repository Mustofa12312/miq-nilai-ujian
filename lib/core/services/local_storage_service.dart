import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _assignmentsKey = 'cache_assignments';
  static const String _studentsPrefix = 'cache_students_class_';
  static const String _pendingScoresKey = 'pending_scores';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  // --- Assignments ---
  Future<void> saveAssignments(List<Map<String, dynamic>> data) async {
    await _prefs.setString(_assignmentsKey, jsonEncode(data));
  }

  List<Map<String, dynamic>>? getAssignments() {
    final str = _prefs.getString(_assignmentsKey);
    if (str == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(str);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  // --- Students ---
  Future<void> saveStudents(int classId, List<Map<String, dynamic>> data) async {
    await _prefs.setString('$_studentsPrefix$classId', jsonEncode(data));
  }

  List<Map<String, dynamic>>? getStudents(int classId) {
    final str = _prefs.getString('$_studentsPrefix$classId');
    if (str == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(str);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  // --- Pending Scores ---
  Future<void> savePendingScore(Map<String, dynamic> scoreData) async {
    final pending = getPendingScores();
    pending.add(scoreData);
    await _prefs.setString(_pendingScoresKey, jsonEncode(pending));
  }

  List<Map<String, dynamic>> getPendingScores() {
    final str = _prefs.getString(_pendingScoresKey);
    if (str == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(str);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearPendingScores() async {
    await _prefs.remove(_pendingScoresKey);
  }
}
