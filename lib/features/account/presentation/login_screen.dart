import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/bonobo_soft_toast.dart';
import '../../journalist/presentation/journalist_screen.dart';

/// Écran de login racine — s'affiche en premier au démarrage de l'app.
/// Authentification OTP email ou réseaux sociaux (lecteur ou journaliste).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  static const int _otpLength = 6;

  /// 'home' | 'email' | 'otp'
  String _step = 'home';
  String _email = '';
  final _emailController = TextEditingController();
  final _otpControllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(_otpLength, (_) => FocusNode());

  late AnimationController _bgController;
  late Animation<double> _bgFade;
  late AnimationController _cardController;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _bgFade = CurvedAnimation(parent: _bgController, curve: Curves.easeIn);

    _cardController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic));
    _cardFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _cardController, curve: Curves.easeOut));

    _bgController.forward();
    Future.delayed(const Duration(milliseconds: 200),
        () => _cardController.forward());
  }

  @override
  void dispose() {
    _bgController.dispose();
    _cardController.dispose();
    _emailController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ── Navigation entre étapes ──────────────────────────────────────────────

  void _goToStep(String step) {
    _cardController.reset();
    setState(() => _step = step);
    _cardController.forward();
  }

  // ── Auth actions ─────────────────────────────────────────────────────────

  Future<void> _onSendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      BonoboSoftToast.show(context,
          message: 'Adresse email invalide.',
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.error);
      return;
    }
    final auth = ref.read(authProvider.notifier);
    try {
      await auth.sendOtp(email, role: 'user');
      setState(() => _email = email);
      _goToStep('otp');
    } catch (e) {
      if (mounted) {
        BonoboSoftToast.show(context,
            message: e.toString(),
            icon: Icons.error_outline_rounded,
            iconColor: AppColors.error);
      }
    }
  }

  Future<void> _onVerifyOtp() async {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length != _otpLength) {
      BonoboSoftToast.show(context,
          message: 'Entrez le code à 6 chiffres.',
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.error);
      return;
    }
    final auth = ref.read(authProvider.notifier);
    try {
      await auth.verifyOtp(_email, code);
      if (mounted) {
        BonoboSoftToast.show(context,
            message: 'Bienvenue sur Bonobo !',
            icon: Icons.check_circle_rounded,
            iconColor: AppColors.primaryGreenStart);
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        BonoboSoftToast.show(context,
            message: e.toString(),
            icon: Icons.error_outline_rounded,
            iconColor: AppColors.error);
      }
    }
  }

  Future<void> _onSocialLogin(String provider) async {
    if (provider == 'Google') {
      try {
        await ref.read(authProvider.notifier).signInWithGoogle();
        if (mounted) {
          BonoboSoftToast.show(context,
              message: 'Bienvenue sur Bonobo !',
              icon: Icons.check_circle_rounded,
              iconColor: AppColors.primaryGreenStart);
          context.go('/');
        }
      } catch (e) {
        if (mounted) {
          BonoboSoftToast.show(context,
              message: e.toString(),
              icon: Icons.error_outline_rounded,
              iconColor: AppColors.error);
        }
      }
    }
  }

  void _continueAsGuest() => context.go('/');

  void _goToJournalist() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const JournalistScreen()),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Si déjà connecté, on redirige immédiatement.
    if (authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/');
      });
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0F0A),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Fond immersif ──────────────────────────────────────────────
            FadeTransition(
              opacity: _bgFade,
              child: Image.asset(
                'assets/images/bonobo_load_bg.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0D1B12), Color(0xFF01200A)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),

            // ── Overlay gradient ───────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x44000000),
                    Color(0xBB000000),
                    Color(0xF5050D08),
                  ],
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
            ),

            // ── Contenu principal ──────────────────────────────────────────
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            _buildHeader(),
                            const Spacer(),
                            FadeTransition(
                              opacity: _cardFade,
                              child: SlideTransition(
                                position: _cardSlide,
                                child: _buildCard(),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Loading overlay ────────────────────────────────────────────
            if (authState.isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primaryGreenStart),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      child: Column(
        children: [
          // Logo - Agrandit pour une meilleure visibilité
          Image.asset(
            'assets/images/logo_white.png',
            height: 100,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Text(
              'BONOBO',
              style: GoogleFonts.poppins(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'L\'information congolaise, en un seul endroit.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white70,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B10).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreenStart.withValues(alpha: 0.08),
            blurRadius: 40,
            spreadRadius: 0,
          ),
        ],
      ),
      child: switch (_step) {
        'email' => _buildEmailStep(),
        'otp' => _buildOtpStep(),
        _ => _buildHomeStep(),
      },
    );
  }

  // ── Étape : Accueil ──────────────────────────────────────────────────────

  Widget _buildHomeStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _sectionTag('BIENVENUE'),
        const SizedBox(height: 12),
        Text(
          'Se connecter\nou créer un compte',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Sauvegardez vos préférences, commentez et suivez vos journalistes favoris.',
          style: GoogleFonts.inter(
              color: Colors.white54, fontSize: 13, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Email (lecteur)
        _PrimaryButton(
          label: 'Continuer avec l\'email',
          icon: Icons.email_outlined,
          onTap: () => _goToStep('email'),
        ),
        const SizedBox(height: 12),

        // Google
        _SocialBtn(
          label: 'Continuer avec Google',
          iconWidget: const _GoogleIcon(),
          onTap: () => _onSocialLogin('Google'),
        ),

        const SizedBox(height: 20),
        _divider(),
        const SizedBox(height: 16),

        // Journaliste
        GestureDetector(
          onTap: _goToJournalist,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.edit_note_rounded,
                  color: AppColors.primaryGreenStart, size: 18),
              const SizedBox(width: 8),
              Text(
                'Espace journaliste',
                style: GoogleFonts.inter(
                  color: AppColors.primaryGreenStart,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.primaryGreenStart, size: 12),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Invité — bouton visible
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _continueAsGuest,
            icon: const Icon(Icons.explore_outlined, size: 16, color: Colors.white60),
            label: Text(
              'Continuer sans compte',
              style: GoogleFonts.inter(
                  color: Colors.white60,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              side: const BorderSide(color: Color(0x33FFFFFF)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Étape : Email ────────────────────────────────────────────────────────

  Widget _buildEmailStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _backButton(onBack: () => _goToStep('home')),
        const SizedBox(height: 12),
        _sectionTag('CONNEXION'),
        const SizedBox(height: 10),
        Text(
          'Entrez votre adresse email',
          style: GoogleFonts.poppins(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Nous vous envoyons un code à usage unique.',
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'votre@email.com',
            hintStyle: const TextStyle(color: Colors.white30),
            prefixIcon: const Icon(Icons.alternate_email_rounded,
                color: AppColors.primaryGreenStart, size: 20),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.white12)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                    color: AppColors.primaryGreenStart, width: 1.5)),
          ),
          onSubmitted: (_) => _onSendOtp(),
        ),
        const SizedBox(height: 16),
        _PrimaryButton(
          label: 'Envoyer le code',
          icon: Icons.send_rounded,
          onTap: _onSendOtp,
        ),
      ],
    );
  }

  // ── Étape : OTP ──────────────────────────────────────────────────────────

  Widget _buildOtpStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _backButton(
            onBack: () {
              for (final c in _otpControllers) {
                c.clear();
              }
              _goToStep('email');
            }),
        const SizedBox(height: 12),
        _sectionTag('VÉRIFICATION'),
        const SizedBox(height: 10),
        Text(
          'Code envoyé !',
          style: GoogleFonts.poppins(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Entrez le code reçu à\n$_email',
          style: GoogleFonts.inter(
              color: Colors.white54, fontSize: 12, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_otpLength, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                width: 40,
                height: 52,
                child: TextField(
                  controller: _otpControllers[i],
                  focusNode: _otpFocusNodes[i],
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (v) {
                    if (v.isNotEmpty && i < _otpLength - 1) {
                      _otpFocusNodes[i + 1].requestFocus();
                    } else if (v.isEmpty && i > 0) {
                      _otpFocusNodes[i - 1].requestFocus();
                    }
                  },
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white12)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primaryGreenStart, width: 2)),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        _PrimaryButton(
          label: 'Vérifier et se connecter',
          icon: Icons.login_rounded,
          onTap: _onVerifyOtp,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () async {
            // Animation de chargement gérée par le provider
            await _onSendOtp();
            if (mounted) {
              BonoboSoftToast.show(context,
                  message: 'Nouveau code envoyé !',
                  icon: Icons.mark_email_read_rounded,
                  iconColor: AppColors.primaryGreenStart);
            }
          },
          child: Text(
            'Renvoyer le code',
            style: GoogleFonts.inter(
                color: AppColors.primaryGreenStart, fontSize: 12),
          ),
        ),
      ],
    );
  }

  // ── Widgets helpers ───────────────────────────────────────────────────────

  Widget _sectionTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryGreenStart.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: AppColors.primaryGreenStart.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: AppColors.primaryGreenStart,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.6,
        ),
      ),
    );
  }

  Widget _backButton({required VoidCallback onBack}) {
    return GestureDetector(
      onTap: onBack,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white54, size: 14),
          const SizedBox(width: 4),
          Text('Retour',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white12, thickness: 0.5)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'ou',
            style: GoogleFonts.inter(color: Colors.white30, fontSize: 11),
          ),
        ),
        const Expanded(child: Divider(color: Colors.white12, thickness: 0.5)),
      ],
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryGreenStart,
          foregroundColor: const Color(0xFF0A1A0A),
          textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w700, fontSize: 14),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final String label;
  final Widget iconWidget;
  final VoidCallback onTap;

  const _SocialBtn(
      {required this.label,
      required this.iconWidget,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Color(0x29FFFFFF)),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icône Google en couleurs officielles (sans SVG externe).
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 22,
      height: 22,
      child: _GooglePainter(),
    );
  }
}

class _GooglePainter extends StatelessWidget {
  const _GooglePainter();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GoogleLogoPainter(), size: const Size(22, 22));
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Fond blanc circulaire
    canvas.drawCircle(
        center, size.width / 2, Paint()..color = Colors.white.withValues(alpha: 0.1));

    // "G" simplifié en couleurs Google — on dessine juste un G stylisé
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 14,
          fontWeight: FontWeight.w700,
          fontFamily: 'Arial',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
