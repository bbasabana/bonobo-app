import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../local_storage.dart';
import '../../features/account/data/auth_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

class AuthState {
  final bool isAuthenticated;
  final String? token;
  final String? role;
  final String? userId;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final bool isLoading;
  final String? error;

  const AuthState({
    required this.isAuthenticated,
    this.token,
    this.role,
    this.userId,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? token,
    String? role,
    String? userId,
    String? email,
    String? displayName,
    String? avatarUrl,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
      role: role ?? this.role,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  AuthNotifier(this._authService)
      : super(AuthState(
          isAuthenticated: LocalStorage.getToken() != null,
          token: LocalStorage.getToken(),
          role: LocalStorage.getUserRole(),
          userId: LocalStorage.getUserId(),
          email: LocalStorage.getUserEmail(),
          displayName: LocalStorage.getDisplayName(),
          avatarUrl: LocalStorage.getAvatarUrl(),
        ));

  // ── OTP flow ──────────────────────────────────────────────────────────────

  /// Étape 1 : envoie le code OTP.
  Future<void> sendOtp(String email, {String role = 'user'}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.sendOtp(email, role: role);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Étape 2 : vérifie le code OTP et connecte l'utilisateur.
  Future<void> verifyOtp(String email, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _authService.verifyOtp(email, otp);
      await _persist(res);
      state = AuthState(
        isAuthenticated: true,
        token: res.token,
        role: res.role,
        userId: res.userId,
        email: res.email,
        displayName: res.displayName,
        avatarUrl: res.avatarUrl,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Connexion via Google.
  Future<void> signInWithGoogle({String role = 'user'}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'Impossible de récupérer le jeton Google ID.';
      }

      final res = await _authService.socialLogin(
        'google',
        idToken,
        email: googleUser.email,
        displayName: googleUser.displayName,
        avatarUrl: googleUser.photoUrl,
        role: role,
      );
      
      await _persist(res);
      state = AuthState(
        isAuthenticated: true,
        token: res.token,
        role: res.role,
        userId: res.userId,
        email: res.email,
        displayName: res.displayName,
        avatarUrl: res.avatarUrl,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  void logout() {
    LocalStorage.logout();
    _googleSignIn.signOut().catchError((_) => null);
    state = const AuthState(isAuthenticated: false);
  }

  Future<void> _persist(AuthResponse res) async {
    await LocalStorage.saveToken(res.token);
    await LocalStorage.saveUserRole(res.role);
    await LocalStorage.saveUserId(res.userId);
    await LocalStorage.saveUserEmail(res.email);
    if (res.displayName != null) {
      await LocalStorage.saveDisplayName(res.displayName!);
    }
    if (res.avatarUrl != null) {
      await LocalStorage.saveAvatarUrl(res.avatarUrl!);
    }
  }
}
