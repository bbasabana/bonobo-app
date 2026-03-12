import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local_storage.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final bool isAuthenticated;
  final String? token;
  final String? role;

  AuthState({required this.isAuthenticated, this.token, this.role});
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier()
      : super(AuthState(
          isAuthenticated: LocalStorage.getToken() != null,
          token: LocalStorage.getToken(),
          role: LocalStorage.getUserRole(),
        ));

  void login(String token, String role) {
    LocalStorage.saveToken(token);
    LocalStorage.saveUserRole(role);
    state = AuthState(isAuthenticated: true, token: token, role: role);
  }

  void logout() {
    LocalStorage.logout();
    state = AuthState(isAuthenticated: false);
  }
}
