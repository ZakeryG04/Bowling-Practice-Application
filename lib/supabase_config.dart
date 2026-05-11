// lib/supabase_config.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://bpjzjdplimyofocfwavi.supabase.co'; // Replace with your Supabase URL
  static const String supabaseAnonKey = 'sb_publishable_pc05zQSc5m0X4v1cPtklRA_mT9hkjlK'; // Replace with your Supabase anon key

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}