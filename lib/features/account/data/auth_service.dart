import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_config.dart';

/// Modèle de réponse auth (OTP ou social).
class AuthResponse {
  final String token;
  final String refreshToken;
  final String userId;
  final String email;
  final String role;
  final String? displayName;
  final String? avatarUrl;

  const AuthResponse({
    required this.token,
    required this.refreshToken,
    required this.userId,
    required this.email,
    required this.role,
    this.displayName,
    this.avatarUrl,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return AuthResponse(
      token: json['token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      userId: user['id'] as String? ?? '',
      email: user['email'] as String? ?? '',
      role: user['role'] as String? ?? 'user',
      displayName: user['displayName'] as String?,
      avatarUrl: user['avatarUrl'] as String?,
    );
  }
}

/// Service d'authentification — contacte le backend Bonobo.
/// Les endpoints sont documentés dans docs/backend-api-auth.md.
class AuthService {
  late final Dio _dio;

  AuthService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: AppConfig.authTimeoutSeconds),
        receiveTimeout: const Duration(seconds: AppConfig.authTimeoutSeconds),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-App-Platform': defaultTargetPlatform.name,
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => debugPrint('[AuthService] $o'),
      ));
    }
  }

  /// Envoie un code OTP par email.
  /// [role] : "user" ou "journalist"
  Future<void> sendOtp(String email, {String role = 'user'}) async {
    try {
      await _dio.post(
        '/api/v1/auth/send-otp',
        data: {'email': email, 'role': role},
      );
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  /// Vérifie l'OTP et retourne les infos utilisateur + tokens.
  Future<AuthResponse> verifyOtp(String email, String otp) async {
    try {
      final res = await _dio.post(
        '/api/v1/auth/verify-otp',
        data: {'email': email, 'otp': otp},
      );
      return AuthResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  /// Connexion via Google ou Facebook.
  /// [provider] : "google" ou "facebook"
  /// [role] : "user" ou "journalist"
  Future<AuthResponse> socialLogin(
    String provider,
    String idToken, {
    String role = 'user',
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/auth/social',
        data: {'provider': provider, 'idToken': idToken, 'role': role},
      );
      return AuthResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  /// Rafraîchit le token d'accès.
  Future<Map<String, String>> refreshToken(String refreshToken) async {
    try {
      final res = await _dio.post(
        '/api/v1/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      return {
        'token': res.data['token'] as String? ?? '',
        'refreshToken': res.data['refreshToken'] as String? ?? '',
      };
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] != null) {
      return data['message'] as String;
    }
    switch (e.response?.statusCode) {
      case 400:
        return 'Email ou code invalide.';
      case 429:
        return 'Trop de tentatives. Réessayez dans quelques minutes.';
      case 401:
        return 'Code incorrect ou expiré.';
      default:
        return 'Erreur réseau. Vérifiez votre connexion.';
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
