import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/bonobo_app_bar.dart';
import '../../../shared/widgets/bonobo_soft_toast.dart';
import '../../../shared/providers/auth_provider.dart';

/// Écran Compte : inscription et authentification des utilisateurs (lecteurs).
/// Même mécanisme que le journaliste (OTP + social) avec role=user pour les stats.
class CompteScreen extends ConsumerStatefulWidget {
  const CompteScreen({super.key});

  @override
  ConsumerState<CompteScreen> createState() => _CompteScreenState();
}

class _CompteScreenState extends ConsumerState<CompteScreen> {
  static const int _otpLength = 6;

  bool _showEmailStep = true;
  bool _showOtpStep = false;
  String _email = '';
  final _emailController = TextEditingController();
  final _otpControllers = List.generate(_otpLength, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(_otpLength, (_) => FocusNode());

  @override
  void dispose() {
    _emailController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onSendOtp() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      BonoboSoftToast.show(
        context,
        message: 'Veuillez entrer une adresse email valide.',
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.error,
      );
      return;
    }
    setState(() {
      _email = email;
      _showEmailStep = false;
      _showOtpStep = true;
    });
    // TODO: POST /api/v1/auth/send-otp { "email": email, "role": "user" }
  }

  void _onVerifyOtp() {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length != _otpLength) {
      BonoboSoftToast.show(
        context,
        message: 'Veuillez entrer le code à 6 chiffres.',
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.error,
      );
      return;
    }
    // TODO: POST /api/v1/auth/verify-otp { "email": _email, "otp": code } → stocker token
    ref.read(authProvider.notifier).login('mock_token_${DateTime.now().millisecondsSinceEpoch}', 'user');
    
    BonoboSoftToast.show(
      context,
      message: 'Vous êtes connecté.',
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.primaryGreenStart,
    );
    if (mounted) context.pop();
  }

  void _onSocialLogin(String provider) {
    // TODO: POST /api/v1/auth/social { "provider": ..., "idToken": ..., "role": "user" }
    BonoboSoftToast.show(
      context,
      message: 'Connexion $provider à venir (Backend API)',
      icon: Icons.info_outline_rounded,
      iconColor: AppColors.primaryGreenStart,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const BonoboAppBar(title: 'Mon compte'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.person_rounded, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'S\'inscrire ou se connecter',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Pour sauvegarder vos préférences, vos médias favoris et vos statistiques de lecture.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            if (_showEmailStep) ..._buildEmailStep(isDark),
            if (_showOtpStep) ..._buildOtpStep(isDark),

            if (_showEmailStep) ...[
              const SizedBox(height: 20),
              _divider(isDark),
              const SizedBox(height: 16),
              Text(
                'Ou continuer avec',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SocialButton(
                      label: 'Google',
                      icon: Icons.g_mobiledata_rounded,
                      onTap: () => _onSocialLogin('Google'),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SocialButton(
                      label: 'Facebook',
                      icon: Icons.facebook_rounded,
                      onTap: () => _onSocialLogin('Facebook'),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEmailStep(bool isDark) {
    return [
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        decoration: InputDecoration(
          hintText: 'Adresse email',
          prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primaryGreen),
          filled: true,
          fillColor: isDark ? const Color(0xFF1E2035) : Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
          ),
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _onSendOtp,
          icon: const Icon(Icons.send_rounded, size: 18),
          label: const Text('Envoyer le code'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildOtpStep(bool isDark) {
    return [
      Text(
        'Code envoyé à $_email',
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white70 : AppColors.textSecondary,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_otpLength, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              width: 44,
              child: TextField(
                controller: _otpControllers[i],
                focusNode: _otpFocusNodes[i],
                keyboardType: TextInputType.number,
                maxLength: 1,
                textAlign: TextAlign.center,
                onChanged: (v) {
                  if (v.isNotEmpty && i < _otpLength - 1) {
                    _otpFocusNodes[i + 1].requestFocus();
                  }
                },
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E2035) : Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _onVerifyOtp,
          icon: const Icon(Icons.login_rounded, size: 18),
          label: const Text('Se connecter'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      const SizedBox(height: 12),
      TextButton(
        onPressed: () => setState(() {
          _showOtpStep = false;
          _showEmailStep = true;
          for (final c in _otpControllers) {
            c.clear();
          }
        }),
        child: const Text('Changer d\'email'),
      ),
    ];
  }

  Widget _divider(bool isDark) {
    return Row(
      children: [
        Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'ou',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.grey.shade300)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 22, color: isDark ? Colors.white70 : AppColors.textPrimary),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
