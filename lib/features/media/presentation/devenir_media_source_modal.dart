import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_config.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/bonobo_soft_toast.dart';

import '../../../core/constants/app_colors.dart';

/// Modal « Devenir média source » — Wizard 3 étapes.
/// Compatible light/dark mode, scroll interne, keyboard-safe.
class DevenirMediaSourceModal extends ConsumerStatefulWidget {
  const DevenirMediaSourceModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (ctx) => const DevenirMediaSourceModal(),
    );
  }

  @override
  ConsumerState<DevenirMediaSourceModal> createState() => _DevenirMediaSourceModalState();
}

enum _FeedStatus { idle, analyzing, valid, invalid }

class _DevenirMediaSourceModalState extends ConsumerState<DevenirMediaSourceModal>
    with TickerProviderStateMixin {

  int _step = 0;
  bool _submitted = false;

  // Step 1
  final _nameController = TextEditingController();
  final _urlController  = TextEditingController();
  String _fluxType = 'wordpress';
  _FeedStatus _feedStatus = _FeedStatus.idle;
  String _feedStatusMsg = '';
  Timer? _debounce;
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  // Step 2 — multi-sélection
  final Set<String> _selectedCategories = {};

  // Step 3
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  // Validation
  String? _nameError;
  String? _urlError;
  String? _categoryError;
  String? _emailError;

  late AnimationController _pageAnim;
  late Animation<double> _fadeAnim;

  static const _fluxTypes = [
    ('wordpress', 'WordPress', Icons.web_rounded),
    ('rss', 'RSS', Icons.rss_feed_rounded),
    ('joomla', 'Joomla', Icons.dns_rounded),
    ('php', 'PHP / Autre', Icons.code_rounded),
  ];

  static const _categories = [
    ('Politique', Icons.account_balance_rounded),
    ('Économie', Icons.trending_up_rounded),
    ('Sport', Icons.sports_soccer_rounded),
    ('Société', Icons.groups_rounded),
    ('International', Icons.language_rounded),
    ('Culture', Icons.theater_comedy_rounded),
    ('Sécurité', Icons.shield_rounded),
    ('Santé', Icons.medical_services_rounded),
    ('Technologie', Icons.computer_rounded),
    ('Environnement', Icons.eco_rounded),
    ('Éducation', Icons.school_rounded),
    ('Général', Icons.article_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _pageAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _fadeAnim = CurvedAnimation(parent: _pageAnim, curve: Curves.easeInOut);
    _pageAnim.value = 1.0;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _urlController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _pageAnim.dispose();
    _dio.close();
    super.dispose();
  }

  // ── Auto-détection URL ────────────────────────────────────────────────────
  void _onUrlChanged(String value) {
    _debounce?.cancel();
    final url = value.trim();
    if (url.length < 12 || !url.startsWith('http')) {
      setState(() { _feedStatus = _FeedStatus.idle; _feedStatusMsg = ''; });
      return;
    }
    setState(() { _feedStatus = _FeedStatus.analyzing; _feedStatusMsg = 'Analyse du flux en cours…'; });
    _debounce = Timer(const Duration(milliseconds: 900), () => _detectFeed(url));
  }

  Future<void> _detectFeed(String url) async {
    final base = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    try {
      final r = await _dio.get('$base/wp-json/wp/v2/posts?per_page=1');
      if (r.statusCode == 200 && r.data is List) {
        if (!mounted) return;
        setState(() { _feedStatus = _FeedStatus.valid; _feedStatusMsg = 'Flux WordPress détecté ✓'; _fluxType = 'wordpress'; });
        return;
      }
    } catch (_) {}
    for (final suffix in ['/feed', '/rss', '/feed.xml', '/rss.xml', '']) {
      try {
        final r = await _dio.get('$base$suffix',
            options: Options(headers: {'Accept': 'application/rss+xml,text/xml,*/*'}));
        final body = r.data?.toString() ?? '';
        if (r.statusCode == 200 && (body.contains('<rss') || body.contains('<feed') || body.contains('<channel'))) {
          if (!mounted) return;
          setState(() { _feedStatus = _FeedStatus.valid; _feedStatusMsg = 'Flux RSS détecté ✓'; _fluxType = 'rss'; });
          return;
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _feedStatus = _FeedStatus.invalid;
      _feedStatusMsg = 'Aucun flux détecté. Vérifiez l\'URL ou choisissez le type.';
    });
  }

  // ── Navigation ────────────────────────────────────────────────────────────
  Future<void> _next() async {
    if (_step == 0 && !_validateStep1()) return;
    if (_step == 1 && !_validateStep2()) return;
    await _pageAnim.reverse();
    setState(() => _step++);
    await _pageAnim.forward();
  }

  Future<void> _back() async {
    await _pageAnim.reverse();
    setState(() => _step--);
    await _pageAnim.forward();
  }

  bool _validateStep1() {
    bool ok = true;
    setState(() {
      _nameError = _nameController.text.trim().isEmpty ? 'Requis' : null;
      _urlError  = _urlController.text.trim().isEmpty ? 'Requis' : null;
      if (_nameError != null || _urlError != null) ok = false;
    });
    return ok;
  }

  bool _validateStep2() {
    if (_selectedCategories.isEmpty) {
      setState(() => _categoryError = 'Choisissez au moins une catégorie');
      return false;
    }
    setState(() => _categoryError = null);
    return true;
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _emailError = 'Email invalide');
      return;
    }
    setState(() => _emailError = null);

    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      BonoboSoftToast.show(context, 
        message: 'Vous devez être connecté pour soumettre un média.',
        icon: Icons.lock_outline_rounded,
        iconColor: Colors.orangeAccent
      );
      return;
    }

    try {
      final data = {
        'siteName': _nameController.text.trim(),
        'feedUrl': _urlController.text.trim(),
        'contactEmail': email,
        'cmsType': _fluxType,
        'userId': auth.userId,
        // Categories can be added if backend supports it, but currently it doesn't seem to store them in site_requests
      };

      final response = await _dio.post('${AppConfig.apiBaseUrl}/api/v1/sites/submit', data: data);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() => _submitted = true);
      } else {
        throw 'Erreur lors de la soumission (${response.statusCode})';
      }
    } catch (e) {
      if (mounted) {
        BonoboSoftToast.show(context,
          message: 'Une erreur est survenue lors de la soumission.',
          icon: Icons.error_outline_rounded,
          iconColor: Colors.redAccent,
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121628) : Colors.white;
    final keyboardH = MediaQuery.of(context).viewInsets.bottom;
    final screenH = MediaQuery.of(context).size.height;

    final auth = ref.watch(authProvider);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Hauteur max = 90% de l'écran, keyboard-safe
      constraints: BoxConstraints(maxHeight: screenH * 0.9),
      padding: EdgeInsets.only(bottom: keyboardH),
      child: !auth.isAuthenticated 
          ? _buildAuthRequired(isDark)
          : (_submitted ? _buildSuccess(isDark) : _buildWizard(isDark)),
    );
  }

  Widget _buildAuthRequired(bool isDark) {
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_person_rounded, color: Colors.orangeAccent, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            'Connexion requise',
            style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Text(
            'Vous devez être connecté pour soumettre un média et suivre l\'état de votre demande.',
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white60 : AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/compte');
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Se connecter / S\'inscrire', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Plus tard', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)),
          ),
        ],
      ),
    );
  }

  // ── Succès ────────────────────────────────────────────────────────────────
  Widget _buildSuccess(bool isDark) {
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.primaryGreenStart, size: 40),
          ),
          const SizedBox(height: 18),
          Text('Demande envoyée !', style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Text(
            'Notre équipe va analyser votre flux. Si validé, vos articles apparaîtront automatiquement sur Bonobo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white60 : AppColors.textSecondary, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: isDark ? 0.08 : 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                _BenefitRow(icon: Icons.visibility_rounded, text: 'Visibilité auprès de milliers de lecteurs', isDark: isDark),
                const SizedBox(height: 8),
                _BenefitRow(icon: Icons.trending_up_rounded, text: 'Boostez votre trafic et votre AdSense', isDark: isDark),
                const SizedBox(height: 8),
                _BenefitRow(icon: Icons.notifications_active_rounded, text: 'Vos articles notifiés en temps réel', isDark: isDark),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Parfait, merci !', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Wizard ────────────────────────────────────────────────────────────────
  Widget _buildWizard(bool isDark) {
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subColor = isDark ? Colors.white60 : AppColors.textSecondary;
    final divColor = isDark ? Colors.white12 : Colors.grey.shade200;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Étape ${_step + 1} sur 3',
                  style: const TextStyle(color: AppColors.primaryGreenStart, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(3, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(left: 5),
                  width: i == _step ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i <= _step ? AppColors.primaryGreenStart : (isDark ? Colors.white24 : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_stepTitle, style: TextStyle(color: textColor, fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(_stepSubtitle, style: TextStyle(color: subColor, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
        Divider(height: 20, color: divColor),
        // Contenu scrollable de l'étape
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: _buildStepContent(isDark),
            ),
          ),
        ),
        // Boutons de navigation fixes en bas
        Divider(height: 1, color: divColor),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: _buildNavButtons(isDark),
        ),
      ],
    );
  }

  String get _stepTitle => switch (_step) {
    0 => 'Votre média',
    1 => 'Catégories',
    _ => 'Contact',
  };

  String get _stepSubtitle => switch (_step) {
    0 => 'Nom et URL de votre flux. Nous détectons le type automatiquement.',
    1 => 'Choisissez une ou plusieurs catégories pour votre média.',
    _ => 'Comment vous contacter pour valider et publier votre média ?',
  };

  // ── Contenu par étape ─────────────────────────────────────────────────────
  Widget _buildStepContent(bool isDark) => switch (_step) {
    0 => _buildStep1(isDark),
    1 => _buildStep2(isDark),
    _ => _buildStep3(isDark),
  };

  // STEP 1 : nom + URL + type
  Widget _buildStep1(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('Nom du média *', isDark),
        const SizedBox(height: 6),
        _InputField(controller: _nameController, hint: 'Ex. Actu Congo…', error: _nameError, isDark: isDark, onChanged: (_) => setState(() => _nameError = null), prefixIcon: Icons.newspaper_rounded),
        const SizedBox(height: 14),
        _FieldLabel('URL du flux *', isDark),
        const SizedBox(height: 6),
        _InputField(
          controller: _urlController,
          hint: 'https://monsite.cd/feed ou https://…',
          error: _urlError,
          keyboardType: TextInputType.url,
          isDark: isDark,
          onChanged: (v) { setState(() => _urlError = null); _onUrlChanged(v); },
          prefixIcon: Icons.link_rounded,
          suffixIcon: switch (_feedStatus) {
            _FeedStatus.analyzing => _SpinnerIcon(isDark: isDark),
            _FeedStatus.valid     => const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreenStart, size: 20),
            _FeedStatus.invalid   => const Icon(Icons.cancel_rounded, color: AppColors.error, size: 20),
            _FeedStatus.idle      => null,
          },
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _feedStatus != _FeedStatus.idle
              ? Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(
                        _feedStatus == _FeedStatus.valid ? Icons.check_rounded : _feedStatus == _FeedStatus.invalid ? Icons.warning_amber_rounded : Icons.hourglass_empty_rounded,
                        size: 13,
                        color: _feedStatus == _FeedStatus.valid ? AppColors.primaryGreenStart : _feedStatus == _FeedStatus.invalid ? AppColors.error : (isDark ? Colors.white54 : Colors.grey),
                      ),
                      const SizedBox(width: 5),
                      Expanded(child: Text(_feedStatusMsg, style: TextStyle(fontSize: 11, color: _feedStatus == _FeedStatus.valid ? AppColors.primaryGreenStart : _feedStatus == _FeedStatus.invalid ? AppColors.error : (isDark ? Colors.white54 : Colors.grey)))),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 14),
        _FieldLabel('Type de flux', isDark),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _fluxTypes.map((e) {
            final sel = _fluxType == e.$1;
            return GestureDetector(
              onTap: () => setState(() => _fluxType = e.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: sel
                      ? AppColors.primaryGreen.withValues(alpha: 0.15)
                      : isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sel ? AppColors.primaryGreenStart : (isDark ? Colors.white24 : Colors.grey.shade300)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(e.$3, size: 15, color: sel ? AppColors.primaryGreenStart : (isDark ? Colors.white60 : AppColors.textSecondary)),
                    const SizedBox(width: 6),
                    Text(e.$2, style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? AppColors.primaryGreenStart : (isDark ? Colors.white70 : AppColors.textSecondary))),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // STEP 2 : catégories (multi-sélection)
  Widget _buildStep2(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_categoryError != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.error, size: 15),
                const SizedBox(width: 7),
                Text(_categoryError!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
              ],
            ),
          ),
        ],
        if (_selectedCategories.isNotEmpty) ...[
          Wrap(
            spacing: 6, runSpacing: 6,
            children: _selectedCategories.map((cat) => Chip(
              label: Text(cat, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.primaryGreen)),
              deleteIcon: const Icon(Icons.close_rounded, size: 14),
              onDeleted: () => setState(() => _selectedCategories.remove(cat)),
              backgroundColor: AppColors.primaryGreen.withValues(alpha: isDark ? 0.15 : 0.1),
              side: BorderSide(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )).toList(),
          ),
          const SizedBox(height: 10),
        ],
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.15,
          children: _categories.map((cat) {
            final sel = _selectedCategories.contains(cat.$1);
            return GestureDetector(
              onTap: () => setState(() {
                _categoryError = null;
                if (sel) {
                  _selectedCategories.remove(cat.$1);
                } else {
                  _selectedCategories.add(cat.$1);
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: sel
                      ? AppColors.primaryGreen.withValues(alpha: isDark ? 0.18 : 0.1)
                      : isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel ? AppColors.primaryGreenStart : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200),
                    width: sel ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(cat.$2, size: 22, color: sel ? AppColors.primaryGreenStart : (isDark ? Colors.white60 : AppColors.textSecondary)),
                    const SizedBox(height: 5),
                    Text(cat.$1, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: sel ? FontWeight.w800 : FontWeight.w500, color: sel ? AppColors.primaryGreenStart : (isDark ? Colors.white70 : AppColors.textSecondary))),
                    if (sel) ...[
                      const SizedBox(height: 2),
                      Icon(Icons.check_circle_rounded, size: 11, color: AppColors.primaryGreenStart),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // STEP 3 : contact
  Widget _buildStep3(bool isDark) {
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subColor = isDark ? Colors.white60 : AppColors.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Résumé
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: isDark ? 0.08 : 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.summarize_rounded, color: AppColors.primaryGreenStart, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_nameController.text.trim().isEmpty ? 'Votre média' : _nameController.text.trim(), style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(
                      [if (_selectedCategories.isNotEmpty) _selectedCategories.join(', '), _fluxTypes.firstWhere((f) => f.$1 == _fluxType).$2].join(' · '),
                      style: TextStyle(color: subColor, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (_feedStatus == _FeedStatus.valid)
                const Icon(Icons.verified_rounded, color: AppColors.primaryGreenStart, size: 18),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _FieldLabel('Téléphone (optionnel)', isDark),
        const SizedBox(height: 6),
        _InputField(controller: _phoneController, hint: '+243 8X X XXX XXXX', keyboardType: TextInputType.phone, isDark: isDark, prefixIcon: Icons.phone_rounded),
        const SizedBox(height: 12),
        _FieldLabel('Email *', isDark),
        const SizedBox(height: 6),
        _InputField(controller: _emailController, hint: 'contact@monmedia.cd', error: _emailError, keyboardType: TextInputType.emailAddress, isDark: isDark, onChanged: (_) => setState(() => _emailError = null), prefixIcon: Icons.email_rounded),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pourquoi rejoindre Bonobo ?', style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 8),
              _BenefitRow(icon: Icons.people_rounded, text: 'Milliers de lecteurs congolais', isDark: isDark),
              const SizedBox(height: 5),
              _BenefitRow(icon: Icons.trending_up_rounded, text: 'Boostez votre trafic et AdSense', isDark: isDark),
              const SizedBox(height: 5),
              _BenefitRow(icon: Icons.check_rounded, text: 'Gratuit — on valide, c\'est en ligne', isDark: isDark),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // ── Boutons navigation ────────────────────────────────────────────────────
  Widget _buildNavButtons(bool isDark) {
    return Row(
      children: [
        if (_step > 0)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _back,
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Retour'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white70 : AppColors.textSecondary,
                side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        if (_step > 0) const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: _step < 2 ? _next : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_step < 2 ? 'Continuer' : 'Soumettre', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(width: 5),
                Icon(_step < 2 ? Icons.arrow_forward_rounded : Icons.send_rounded, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Widgets helpers ──────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _FieldLabel(this.text, this.isDark);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: isDark ? Colors.white70 : AppColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? error;
  final bool isDark;
  final TextInputType keyboardType;
  final void Function(String)? onChanged;
  final IconData? prefixIcon;
  final Widget? suffixIcon;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.isDark,
    this.error,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor = isDark
        ? (error != null ? Colors.white.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.06))
        : (error != null ? Colors.red.withValues(alpha: 0.03) : Colors.grey.shade50);
    final borderColor = error != null ? AppColors.error : (isDark ? Colors.white24 : Colors.grey.shade300);
    final focusBorderColor = error != null ? AppColors.error : AppColors.primaryGreenStart;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final hintColor = isDark ? Colors.white38 : Colors.grey.shade400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: TextStyle(color: textColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: hintColor, fontSize: 14),
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: isDark ? Colors.white38 : Colors.grey.shade400) : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: focusBorderColor, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, size: 12, color: AppColors.error),
              const SizedBox(width: 4),
              Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 11)),
            ],
          ),
        ],
      ],
    );
  }
}

class _SpinnerIcon extends StatelessWidget {
  final bool isDark;
  const _SpinnerIcon({required this.isDark});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(12),
    child: SizedBox(
      width: 16, height: 16,
      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreenStart),
    ),
  );
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  const _BenefitRow({required this.icon, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 14, color: AppColors.primaryGreenStart),
      const SizedBox(width: 7),
      Expanded(child: Text(text, style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary, fontSize: 12, height: 1.4))),
    ],
  );
}
