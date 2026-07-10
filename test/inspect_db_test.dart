import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('inspect dosen_pembimbing relations', () async {
    final client = SupabaseClient(
      'https://ihjaeolsecdvegwfdmvf.supabase.co',
      'sb_publishable_Mi-6Gv1vD5R2CzHskKvq-g_pZd9iDFy',
    );

    final res = await client
        .from('dosen_pembimbing')
        .select('*, mahasiswa:mahasiswa_id(nama), dosen:dosen_id(nama)');
    debugPrint('dosen_pembimbing relations: $res');

    final bookings = await client
        .from('booking')
        .select('*, mahasiswa:mahasiswa_id(nama), dosen:dosen_id(nama)');
    debugPrint('All bookings: $bookings');
  });
}
