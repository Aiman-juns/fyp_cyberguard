import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../../config/supabase_config.dart';
import '../../core/services/avatar_service.dart';

/// Auth State enum
enum AuthState { loading, authenticated, unauthenticated, error }

/// Exception for auth errors
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

/// Authentication Provider
/// Manages login, register, logout, and auth state
class AuthProvider extends StateNotifier<AsyncValue<UserModel?>> {
  AuthProvider() : super(const AsyncValue.data(null)) {
    _checkAuthState();
  }

  /// Check if user is already authenticated
  Future<void> _checkAuthState() async {
    try {
      final user = SupabaseConfig.currentUser;
      if (user != null) {
        // Fetch user profile from database
        final userProfile = await _fetchUserProfile(user.id);
        state = AsyncValue.data(userProfile);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Fetch user profile from database
  Future<UserModel> _fetchUserProfile(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw AuthException('Failed to fetch user profile: $e');
    }
  }

  /// Login with email and password
  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        final userProfile = await _fetchUserProfile(user.id);
        state = AsyncValue.data(userProfile);
      } else {
        throw AuthException('Invalid credentials');
      }
    } on AuthException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    } catch (e) {
      // Simplify error message for better UX
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('invalid') || errorMsg.contains('credentials')) {
        throw AuthException('Invalid credentials');
      }
      final error = AuthException('Login failed: $e');
      state = AsyncValue.error(error, StackTrace.current);
      rethrow;
    }
  }

  /// Register with email, password, and full name
  Future<void> register(
    String email,
    String password,
    String fullName, {
    bool isAdmin = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Sign up with Supabase Auth
      final authResponse = await SupabaseConfig.client.auth.signUp(
        email: email,
        password: password,
      );

      final user = authResponse.user;
      if (user != null) {
        // Generate random avatar ID
        final avatarId = AvatarService.getRandomAvatarId();
        
        // Generate avatar URL from name
        // For Phase 1, using simple DiceBear initials
        final avatarUrl =
            'https://api.dicebear.com/9.x/initials/svg?seed=${fullName.replaceAll(' ', '')}&backgroundColor=0066CC,00CC66,FF3333&textColor=ffffff';

        // Create user profile in database
        final newUser = UserModel(
          id: user.id,
          email: email,
          fullName: fullName,
          role: 'user',
          avatarUrl: avatarUrl,
          avatarId: avatarId,
          totalScore: 0,
          level: 1,
        );

        await SupabaseConfig.client.from('users').insert(newUser.toJson());

        state = AsyncValue.data(newUser);
      } else {
        throw AuthException('Registration failed: No user returned');
      }
    } on AuthException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    } catch (e) {
      final error = AuthException('Registration failed: $e');
      state = AsyncValue.error(error, StackTrace.current);
      rethrow;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await SupabaseConfig.client.auth.signOut();
      state = const AsyncValue.data(null);
    } catch (e) {
      final error = AuthException('Logout failed: $e');
      state = AsyncValue.error(error, StackTrace.current);
      rethrow;
    }
  }

  /// Check if authenticated
  bool get isAuthenticated =>
      state.maybeWhen(data: (user) => user != null, orElse: () => false);
}

/// Riverpod provider for authentication
final authProvider =
    StateNotifierProvider<AuthProvider, AsyncValue<UserModel?>>(
      (ref) => AuthProvider(),
    );

/// Convenience provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref
      .watch(authProvider)
      .maybeWhen(data: (user) => user != null, orElse: () => false);
});

/// Convenience provider to get current user
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref
      .watch(authProvider)
      .maybeWhen(data: (user) => user, orElse: () => null);
});
