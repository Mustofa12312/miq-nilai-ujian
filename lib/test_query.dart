import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  final supabaseUrl = dotenv.env['SUPABASE_URL']!;
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY']!;
  
  final supabase = SupabaseClient(supabaseUrl, supabaseKey);
  
  try {
    final res = await supabase.from('examiner_assignments').select('id, gender').limit(1);
    print('Examiner assignments gender OK: $res');
  } catch (e) {
    print('Error examiner_assignments: $e');
  }

  try {
    final res = await supabase.from('students').select('id, gender').limit(1);
    print('Students gender OK: $res');
  } catch (e) {
    print('Error students: $e');
  }

  try {
    final res = await supabase.from('scores').select('student_id, students!inner(gender)').limit(1);
    print('Scores inner gender OK: $res');
  } catch (e) {
    print('Error scores inner: $e');
  }
}
