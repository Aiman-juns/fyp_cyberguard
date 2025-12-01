import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Configuration
///
/// To get your credentials:
/// 1. Go to https://app.supabase.com
/// 2. Create a new project or select existing
/// 3. Go to Settings > API > Project Settings
/// 4. Copy your Project URL and Anon Key
class SupabaseConfig {
  static const String supabaseUrl = 'https://jndkxmtdjpdabckhlrjj.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpuZGt4bXRkanBkYWJja2hscmpqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM1NjMyNzcsImV4cCI6MjA3OTEzOTI3N30.3pVoOVjQeCYpAVrFD9xT3KdUQuP4m6cp8oR-FZ8e-XY';

  /// Initialize Supabase
  /// Call this in main.dart before running the app
  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  /// Get the Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  /// Get the authenticated user
  static User? get currentUser => client.auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;
}
