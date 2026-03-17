import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../account/presentation/widgets/journalist_modals.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/bonobo_soft_toast.dart';
import '../../account/presentation/widgets/journalist_modals.dart';

/// Espace Journaliste : fond immersif avec bonobo_load_bg.jpg,
/// texte valorisant les journalistes indépendants, OTP + social.
class JournalistScreen extends ConsumerStatefulWidget {
  const JournalistScreen({super.key});

  @override
  ConsumerState<JournalistScreen> createState() => _JournalistScreenState();
}

class _JournalistScreenState extends ConsumerState<JournalistScreen>
    with TickerProviderStateMixin {
  static const int _otpLength = 6;

  bool _showAuthForm = false;
  bool _showOtpStep = false;
  String _email = '';
  final _emailController = TextEditingController();
  final _otpControllers = List.generate(_otpLength, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(_otpLength, (_) => FocusNode());

  late AnimationController _entryController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _emailController.dispose();
    for (final c in _otpControllers) { c.dispose(); }
    for (final f in _otpFocusNodes) { f.dispose(); }
    super.dispose();
  }

  Future<void> _onSendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      BonoboSoftToast.show(context,
          message: 'Entrez une adresse email valide.',
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.error);
      return;
    }
    try {
      await ref.read(authProvider.notifier).sendOtp(email, role: 'journalist');
      setState(() {
        _email = email;
        _showOtpStep = true;
      });
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
    try {
      await ref.read(authProvider.notifier).verifyOtp(_email, code);

      if (mounted) {
        BonoboSoftToast.show(context,
            message: 'Connexion réussie ! Bienvenue, journaliste.',
            icon: Icons.check_circle_rounded,
            iconColor: AppColors.primaryGreenStart);
        Navigator.of(context).maybePop();
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

  void _onSocialLogin(String provider) {
    if (provider == 'Google') {
      ref.read(authProvider.notifier).signInWithGoogle(role: 'journalist')
        .then((_) {
          if (mounted) Navigator.of(context).maybePop();
        })
        .catchError((e) {
          if (mounted) {
            BonoboSoftToast.show(context,
                message: e.toString(),
                icon: Icons.error_outline_rounded,
                iconColor: AppColors.error);
          }
        });
    }
  }

  void _showLearnMore() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F1923),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Pourquoi rejoindre Bonobo ?',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
              const SizedBox(height: 10),
              const Text(
                'Une plateforme conçue pour la liberté et l\'impact.',
                style: TextStyle(color: AppColors.primaryGreenStart, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 32),
              
              _LearnMoreItem(
                icon: Icons.auto_graph_rounded,
                title: 'Audience & Visibilité',
                desc: 'Vos articles sont propulsés auprès de milliers d\'utilisateurs actifs dès la publication. Ne dépendez plus des algorithmes des réseaux sociaux.',
              ),
              _LearnMoreItem(
                icon: Icons.verified_user_rounded,
                title: 'Crédibilité Certifiée',
                desc: 'Bénéficiez du badge "Journaliste Vérifié". Votre identité est protégée et votre expertise est reconnue par notre communauté.',
              ),
              _LearnMoreItem(
                icon: Icons.payments_rounded,
                title: 'Monétisation Directe',
                desc: 'Gagnez des revenus basés sur l\'engagement de vos lecteurs. Un système transparent qui valorise la qualité de l\'information.',
              ),
              _LearnMoreItem(
                icon: Icons.analytics_rounded,
                title: 'Outils Avancés',
                desc: 'Accédez à un tableau de bord complet : statistiques précises, gestion des commentaires et outils de promotion de vos articles.',
              ),
              
              const SizedBox(height: 40),
              const Divider(color: Colors.white10),
              const SizedBox(height: 40),

              const Text(
                'Pour les Médias & Éditeurs',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Bonobo n\'est pas un concurrent, c\'est votre partenaire de croissance. En intégrant votre flux RSS/API, vous boostez votre trafic sortant et vos revenus publicitaires.',
                style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
              ),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('J\'ai compris', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background immersif
            Image.asset(
              'assets/images/bonobo_load_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              ),
            ),

            // ── Gradient sombre sur toute la hauteur
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x60000000),
                    Color(0xCC000000),
                    Color(0xF0000000),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // ── Contenu
            SafeArea(
              child: Column(
                children: [
                  // AppBar minimal
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        const Spacer(),
                        // Badge "JOURNALISTE"
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreenStart.withValues(alpha: 0.2),
                            border: Border.all(color: AppColors.primaryGreenStart, width: 1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded, color: AppColors.primaryGreenStart, size: 14),
                              SizedBox(width: 5),
                              Text(
                                'JOURNALISTE BONOBO',
                                style: TextStyle(
                                  color: AppColors.primaryGreenStart,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // ── Contenu principal animé
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _showAuthForm ? _buildAuthPanel() : _buildLandingPanel(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandingPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Premium Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryGreenStart.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.primaryGreenStart.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'REVOLUTION INDEPENDANTE',
              style: TextStyle(
                color: AppColors.primaryGreenStart,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Main Title with Rich Typography
          ShaderMask(
            shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
            child: const Text(
              'VALORISER\nVOTRE PLUME.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w900,
                height: 0.95,
                letterSpacing: -1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Impact Statement
          const Text(
            'Bonobo est le premier agrégateur qui place le journaliste indépendant au cœur de l\'information. Pas besoin de média, votre intégrité est votre plus grand atout.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 32),

          // Key Value Pillars
          _ValueRow(icon: Icons.auto_awesome_rounded, text: 'Visibilité nationale immédiate'),
          const SizedBox(height: 12),
          _ValueRow(icon: Icons.verified_user_rounded, text: 'Certification de journaliste vérifié'),
          const SizedBox(height: 12),
          _ValueRow(icon: Icons.monetization_on_rounded, text: 'Monétisation de votre audience'),
          
          const SizedBox(height: 48),

          // Multi-action CTA
          Row(
            children: [
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () {
                    final auth = ref.read(authProvider);
                    if (auth.isAuthenticated) {
                      if (auth.role == 'journalist') {
                        BonoboSoftToast.show(context,
                            message: 'Vous êtes déjà journaliste.',
                            icon: Icons.info_outline_rounded,
                            iconColor: AppColors.primaryGreenStart);
                      } else {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const JournalistApplicationModal(),
                        );
                      }
                    } else {
                      setState(() => _showAuthForm = true);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Devenir Journaliste',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _showLearnMore, // Savoir plus
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    side: const BorderSide(color: Colors.white30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'En savoir +',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Center(
            child: GestureDetector(
              onTap: () => setState(() => _showAuthForm = true),
            child: RichText(
                text: TextSpan(
                  text: ref.watch(authProvider).isAuthenticated 
                      ? 'Compte connecté' 
                      : 'Vous avez déjà un compte ? ',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                  children: [
                    if (!ref.watch(authProvider).isAuthenticated)
                      const TextSpan(
                        text: 'Se connecter',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1923).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                'Créer mon compte',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () =>     setState(() {
          _showAuthForm = false;
          _showOtpStep = false;
          _emailController.clear();
          for (final c in _otpControllers) { c.clear(); }
        }),
                child: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Connexion sans mot de passe',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 20),

          if (!_showOtpStep) ...[
            _buildEmailField(),
            const SizedBox(height: 14),
            _buildSendOtpBtn(),
            const SizedBox(height: 18),
            _buildDivider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _SocialBtn(label: 'Google', icon: Icons.g_mobiledata_rounded, onTap: () => _onSocialLogin('Google'))),
              ],
            ),
          ] else ...[
            Text(
              'Code envoyé à $_email',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            _buildOtpFields(),
            const SizedBox(height: 16),
            _buildVerifyBtn(),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () => setState(() {
                  _showOtpStep = false;
                  for (final c in _otpControllers) { c.clear(); }
                }),
                child: const Text('Changer d\'email', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Adresse email professionnelle',
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primaryGreenStart, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGreenStart, width: 1.5)),
      ),
    );
  }

  Widget _buildSendOtpBtn() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _onSendOtp,
        icon: const Icon(Icons.send_rounded, size: 16),
        label: const Text('Envoyer le code'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildOtpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_otpLength, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SizedBox(
            width: 42,
            child: TextField(
              controller: _otpControllers[i],
              focusNode: _otpFocusNodes[i],
              keyboardType: TextInputType.number,
              maxLength: 1,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              onChanged: (v) {
                if (v.isNotEmpty && i < _otpLength - 1) _otpFocusNodes[i + 1].requestFocus();
              },
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryGreenStart, width: 1.5)),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildVerifyBtn() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _onVerifyOtp,
        icon: const Icon(Icons.login_rounded, size: 16),
        label: const Text('Confirmer et rejoindre'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryGreenStart,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: const [
        Expanded(child: Divider(color: Colors.white12)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('ou', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ),
        Expanded(child: Divider(color: Colors.white12)),
      ],
    );
  }
}

class _ValueRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ValueRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryGreenStart, size: 20),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
              color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SocialBtn({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: Colors.white70),
      label: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10),
        side: const BorderSide(color: Colors.white24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _LearnMoreItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _LearnMoreItem({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primaryGreenStart, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 14, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
