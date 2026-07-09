import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('inspect users table columns', () async {
    final client = SupabaseClient(
      'https://ihjaeolsecdvegwfdmvf.supabase.co',
      'sb_publishable_Mi-6Gv1vD5R2CzHskKvq-g_pZd9iDFy',
    );

    try {
      await client.from('users').insert({'phone': '12345'});
    } catch (e) {
      print('USERS INSERT ERROR: $e');
    }
  });
}
