import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/bonobo_app_bar.dart';
import '../../../shared/widgets/bonobo_soft_toast.dart';
import '../../../shared/providers/auth_provider.dart';
import 'compte_screen.dart';

import 'widgets/journalist_modals.dart';
import '../data/journalist_application_service.dart';
import '../../media/presentation/devenir_media_source_modal.dart';
import '../../news/presentation/screens/saved_articles_screen.dart';
import 'notifications_screen.dart';

/// Écran Compte : profil connecté ou formulaire d'inscription.
class CompteScreen extends ConsumerStatefulWidget {
  const CompteScreen({super.key});

  @override
  ConsumerState<CompteScreen> createState() => _CompteScreenState();
}

class _CompteScreenState extends ConsumerState<CompteScreen> {
  static const int _otpLength = 6;
  bool _showOtpStep = false;
  String _email = '';
  final _emailController = TextEditingController();
  final _otpControllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(_otpLength, (_) => FocusNode());
  List<dynamic> _ownedMedia = [];
  bool _loadingMedia = false;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkJournalistData();
    });
  }

  Future<void> _checkJournalistData() async {
    final auth = ref.read(authProvider);
    if (auth.isAuthenticated && auth.role == 'journalist') {
      _fetchOwnedMedia();
    }
  }

  Future<void> _fetchOwnedMedia() async {
    setState(() => _loadingMedia = true);
    final service = JournalistApplicationService(token: ref.read(authProvider).token);
    final data = await service.getJournalistDashboard();
    if (mounted && data != null) {
      setState(() {
        _ownedMedia = data['sources'] ?? [];
        _loadingMedia = false;
      });
    } else if (mounted) {
      setState(() => _loadingMedia = false);
    }
  }

  Future<void> _onSendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      BonoboSoftToast.show(context,
          message: 'Veuillez entrer une adresse email valide.',
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.error);
      return;
    }
    try {
      await ref.read(authProvider.notifier).sendOtp(email, role: 'user');
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
          message: 'Veuillez entrer le code à 6 chiffres.',
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.error);
      return;
    }
    try {
      await ref.read(authProvider.notifier).verifyOtp(_email, code);
      if (mounted) {
        BonoboSoftToast.show(context,
            message: 'Vous êtes connecté.',
            icon: Icons.check_circle_rounded,
            iconColor: AppColors.primaryGreenStart);
        context.pop();
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
    BonoboSoftToast.show(context,
        message: 'Connexion $provider — intégration SDK à compléter.',
        icon: Icons.info_outline_rounded,
        iconColor: AppColors.primaryGreenStart);
  }

  Future<void> _onLogout() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E2035) : Colors.white,
        title: Text('Déconnexion',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary)),
        content: Text('Voulez-vous vraiment vous déconnecter de votre compte ?',
            style: GoogleFonts.inter(
                color: isDark ? Colors.white70 : AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Se déconnecter',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const BonoboAppBar(title: 'Mon compte'),
      body: auth.isAuthenticated
          ? _buildProfile(auth, isDark)
          : SingleChildScrollView(
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
                      child: Icon(Icons.person_rounded,
                          color: Colors.white, size: 32),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'S\'inscrire ou se connecter',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pour sauvegarder vos préférences, vos médias favoris et vos statistiques de lecture.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color:
                          isDark ? Colors.white60 : AppColors.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  if (!_showOtpStep) ..._buildEmailStep(isDark),
                  if (_showOtpStep) ..._buildOtpStep(isDark),

                  if (!_showOtpStep) ...[
                    const SizedBox(height: 20),
                    _divider(isDark),
                    const SizedBox(height: 16),
                    Text(
                      'Ou continuer avec',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white54
                            : AppColors.textSecondary,
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

  // ── Profil connecté ──────────────────────────────────────────────────────

  Widget _buildProfile(AuthState auth, bool isDark) {
    final avatarBg = isDark ? const Color(0xFF1A2E1C) : const Color(0xFFE8F5E9);
    final card = isDark ? const Color(0xFF1E2035) : Colors.white;
    final textPrimary = isDark ? Colors.white : AppColors.textPrimary;
    final textSecondary = isDark ? Colors.white60 : AppColors.textSecondary;

    final initials = (auth.displayName?.isNotEmpty == true
            ? auth.displayName![0]
            : auth.email?.isNotEmpty == true
                ? auth.email![0]
                : 'B')
        .toUpperCase();

    final roleLabel = auth.role == 'journalist'
        ? 'Journaliste Bonobo'
        : 'Lecteur Bonobo';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Avatar + nom
        Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryGreenStart, AppColors.primaryGreenEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreenStart.withValues(alpha: 0.3),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(initials,
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 12),
              if (auth.displayName != null)
                Text(auth.displayName!,
                    style: GoogleFonts.poppins(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              if (auth.email != null)
                Text(auth.email!,
                    style: GoogleFonts.inter(
                        color: textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreenStart.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primaryGreenStart
                          .withValues(alpha: 0.3)),
                ),
                child: Text(roleLabel,
                    style: GoogleFonts.inter(
                        color: AppColors.primaryGreenStart,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Infos compte
        Container(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8)
            ],
          ),
          child: Column(
            children: [
              _ProfileRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: auth.email ?? '—',
                  isDark: isDark),
              _ProfileDivider(isDark: isDark),
              _ProfileRow(
                  icon: Icons.badge_outlined,
                  label: 'Rôle',
                  value: auth.role == 'journalist'
                      ? 'Journaliste'
                      : 'Lecteur',
                  isDark: isDark),
              _ProfileDivider(isDark: isDark),
              _ProfileRow(
                  icon: Icons.fingerprint_rounded,
                  label: 'ID',
                  value: auth.userId != null
                      ? 'ID-${auth.userId!.substring(0, 8).toUpperCase()}'
                      : '—',
                  isDark: isDark),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Actions
        Container(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              if (auth.role == 'user') ...[
                ListTile(
                  leading: const Icon(Icons.edit_note_rounded,
                      color: AppColors.primaryGreen),
                  title: Text('Postuler comme journaliste',
                      style: GoogleFonts.inter(
                          color: textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text('Devenez contributeur sur Bonobo',
                      style: GoogleFonts.inter(
                          color: textSecondary, fontSize: 11)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14),
                  onTap: () => _showJournalistApplication(),
                ),
                const Divider(height: 1, indent: 16),
                ListTile(
                  leading: const Icon(Icons.add_business_rounded,
                      color: AppColors.primaryGreen),
                  title: Text('Soumettre un média',
                      style: GoogleFonts.inter(
                          color: textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text('Ajoutez un flux RSS sur la plateforme',
                      style: GoogleFonts.inter(
                          color: textSecondary, fontSize: 11)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14),
                  onTap: () => DevenirMediaSourceModal.show(context),
                ),
                const Divider(height: 1, indent: 16),
              ],
              
              if (auth.role == 'journalist') ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('MES MÉDIAS & CERTIFICATION',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryGreen, letterSpacing: 1.0)),
                      if (_loadingMedia)
                        const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen)),
                    ],
                  ),
                ),
                if (_ownedMedia.isEmpty && !_loadingMedia)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Aucun média associé à votre compte.', style: GoogleFonts.inter(fontSize: 12, color: textSecondary)),
                  ),
                ..._ownedMedia.map((m) => _buildMediaCertificationTile(m, isDark, textPrimary, textSecondary)),
                const SizedBox(height: 16),
                const Divider(height: 1, indent: 16),
              ],

              ListTile(
                leading: const Icon(Icons.bookmark_outline_rounded,
                    color: AppColors.primaryGreen),
                title: Text('Articles sauvegardés',
                    style: GoogleFonts.inter(
                        color: textPrimary, fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14),
                onTap: () => context.push('/saved-articles'),
              ),
              const Divider(height: 1, indent: 16),
              ListTile(
                leading: const Icon(Icons.notifications_outlined,
                    color: AppColors.primaryGreen),
                title: Text('Notifications',
                    style: GoogleFonts.inter(
                        color: textPrimary, fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14),
                onTap: () => context.push('/notifications'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Déconnexion
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _onLogout,
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            label: Text('Se déconnecter',
                style: GoogleFonts.inter(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ── Formulaire email ─────────────────────────────────────────────────────

  List<Widget> _buildEmailStep(bool isDark) {
    return [
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        decoration: InputDecoration(
          hintText: 'Adresse email',
          prefixIcon: const Icon(Icons.email_outlined,
              color: AppColors.primaryGreen),
          filled: true,
          fillColor:
              isDark ? const Color(0xFF1E2035) : Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: AppColors.primaryGreen, width: 1.5),
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    ];
  }

  // ── Formulaire OTP ───────────────────────────────────────────────────────

  List<Widget> _buildOtpStep(bool isDark) {
    return [
      Text(
        'Code envoyé à $_email',
        style: GoogleFonts.inter(
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
                  fillColor: isDark
                      ? const Color(0xFF1E2035)
                      : Colors.grey.shade50,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: isDark
                            ? Colors.white12
                            : Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.primaryGreen, width: 1.5),
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      const SizedBox(height: 12),
      TextButton(
        onPressed: () => setState(() {
          _showOtpStep = false;
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
        Expanded(
            child: Divider(
                color: isDark ? Colors.white24 : Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('ou',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white54 : AppColors.textSecondary,
              )),
        ),
        Expanded(
            child: Divider(
                color: isDark ? Colors.white24 : Colors.grey.shade300)),
      ],
    );
  }

  void _showJournalistApplication() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const JournalistApplicationModal(),
    );
  }

  void _showMediaSubmission(String? userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MediaSubmissionModal(userId: userId),
    );
  }

  Widget _buildMediaCertificationTile(Map<String, dynamic> m, bool isDark, Color textPrimary, Color textSecondary) {
    final cert = m['certification'] ?? 'none';
    final status = m['certificationRequestStatus'] ?? 'none';
    
    IconData icon = Icons.verified_user_outlined;
    Color color = AppColors.primaryGreen;
    String label = 'Non certifié';

    if (cert == 'blue') {
      icon = Icons.verified_rounded;
      color = Colors.blue;
      label = 'Officiel';
    } else if (cert == 'green') {
      icon = Icons.verified_user_rounded;
      color = AppColors.primaryGreenStart;
      label = 'Partenaire';
    } else if (cert == 'yellow') {
      icon = Icons.report_problem_rounded;
      color = Colors.amber;
      label = 'Observateur';
    } else if (cert == 'red') {
      icon = Icons.warning_rounded;
      color = Colors.red;
      label = 'Urgent';
    }

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(m['name'] ?? 'Média sans nom', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: textPrimary, fontSize: 13)),
      subtitle: Text(
        status == 'pending' ? 'Demande en attente...' : label,
        style: GoogleFonts.inter(fontSize: 11, color: status == 'pending' ? Colors.amber : textSecondary),
      ),
      trailing: (cert == 'none' && status != 'pending') 
        ? TextButton(
            onPressed: () => _showCertificationRequest(m),
            child: const Text('Certifier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          )
        : null,
    );
  }

  void _showCertificationRequest(Map<String, dynamic> media) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MediaCertificationRequestModal(media: media),
    );
    if (result == true) {
      _fetchOwnedMedia();
    }
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _ProfileRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: 12),
          Text(label,
              style: GoogleFonts.inter(
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                  fontSize: 13)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.inter(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ProfileDivider extends StatelessWidget {
  final bool isDark;

  const _ProfileDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
        height: 1,
        indent: 16,
        color: isDark ? Colors.white12 : Colors.grey.shade100);
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
      icon: Icon(icon,
          size: 22,
          color: isDark ? Colors.white70 : AppColors.textPrimary),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(
            color: isDark ? Colors.white24 : Colors.grey.shade300),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

