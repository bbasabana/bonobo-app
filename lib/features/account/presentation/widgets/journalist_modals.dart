import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/bonobo_soft_toast.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../data/journalist_application_service.dart';

class JournalistApplicationModal extends ConsumerStatefulWidget {
  const JournalistApplicationModal({super.key});

  @override
  ConsumerState<JournalistApplicationModal> createState() =>
      _JournalistApplicationModalState();
}

class _JournalistApplicationModalState
    extends ConsumerState<JournalistApplicationModal> {
  final _bioController = TextEditingController();
  final _mediaNameController = TextEditingController();
  String _type = 'independent'; // independent | media
  bool _isLoading = false;

  @override
  void dispose() {
    _bioController.dispose();
    _mediaNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final bio = _bioController.text.trim();
    final mediaName = _mediaNameController.text.trim();

    if (bio.isEmpty) {
      BonoboSoftToast.show(context,
          message: 'Veuillez rédiger votre profil professionnel.',
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.error);
      return;
    }

    if (_type == 'media' && mediaName.isEmpty) {
      BonoboSoftToast.show(context,
          message: 'Veuillez préciser le nom du média.',
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.error);
      return;
    }

    setState(() => _isLoading = true);

    final service = JournalistApplicationService(
        token: ref.read(authProvider).token);
    final success = await service.submitJournalistApplication(
      type: _type,
      bio: bio,
      mediaName: _type == 'media' ? mediaName : null,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        BonoboSoftToast.show(context,
            message: 'Demande envoyée ! Un admin étudiera votre profil.',
            icon: Icons.check_circle_rounded,
            iconColor: AppColors.primaryGreenStart);
        Navigator.pop(context);
      } else {
        BonoboSoftToast.show(context,
            message: 'Erreur lors de l\'envoi.',
            icon: Icons.error_outline_rounded,
            iconColor: AppColors.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final textPrimary = isDark ? Colors.white : AppColors.textPrimary;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2035) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Devenir journalist',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 18, color: textPrimary)),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Quel est votre profil ?',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TypeSelect(
                  label: 'Indépendant',
                  icon: Icons.person_search_rounded,
                  isSelected: _type == 'independent',
                  onTap: () => setState(() => _type = 'independent'),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TypeSelect(
                  label: 'Dans un média',
                  icon: Icons.business_center_rounded,
                  isSelected: _type == 'media',
                  onTap: () => setState(() => _type = 'media'),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          if (_type == 'media') ...[
            const SizedBox(height: 20),
            _buildField(
              controller: _mediaNameController,
              label: 'Nom du média',
              hint: 'Ex: Zoom Eco, Actualite.cd',
              icon: Icons.business_rounded,
              isDark: isDark,
            ),
          ],
          const SizedBox(height: 20),
          _buildField(
            controller: _bioController,
            label: 'Votre profil professionnel / Bio',
            hint: 'Décrivez votre expérience et vos domaines de prédilection...',
            icon: Icons.description_outlined,
            isDark: isDark,
            maxLines: 4,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Envoyer ma demande de migration'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: maxLines == 1 ? Icon(icon, color: AppColors.primaryGreen, size: 20) : null,
            filled: true,
            fillColor: isDark ? const Color(0xFF141625) : Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)),
          ),
        ),
      ],
    );
  }
}

class _TypeSelect extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _TypeSelect({required this.label, required this.icon, required this.isSelected, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreenStart.withValues(alpha: 0.1) : (isDark ? const Color(0xFF141625) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppColors.primaryGreenStart : (isDark ? Colors.white10 : Colors.grey.shade200), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primaryGreenStart : (isDark ? Colors.white38 : Colors.grey.shade400)),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? AppColors.primaryGreenStart : (isDark ? Colors.white70 : AppColors.textPrimary))),
          ],
        ),
      ),
    );
  }
}

class MediaSubmissionModal extends ConsumerStatefulWidget {
  final String? userId;
  const MediaSubmissionModal({super.key, this.userId});

  @override
  ConsumerState<MediaSubmissionModal> createState() => _MediaSubmissionModalState();
}

class _MediaSubmissionModalState extends ConsumerState<MediaSubmissionModal> {
  final _siteNameController = TextEditingController();
  final _feedUrlController = TextEditingController();
  final _contactEmailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _siteNameController.dispose();
    _feedUrlController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final siteName = _siteNameController.text.trim();
    final feedUrl = _feedUrlController.text.trim();
    final contactEmail = _contactEmailController.text.trim();

    if (siteName.isEmpty || feedUrl.isEmpty || contactEmail.isEmpty) {
      BonoboSoftToast.show(context, message: 'Veuillez remplir tous les champs.', icon: Icons.error_outline_rounded, iconColor: AppColors.error);
      return;
    }

    setState(() => _isLoading = true);
    final service = JournalistApplicationService(token: ref.read(authProvider).token);
    final success = await service.submitMediaSite(siteName: siteName, feedUrl: feedUrl, contactEmail: contactEmail, userId: widget.userId);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        BonoboSoftToast.show(context, message: 'Média envoyé avec succès !', icon: Icons.check_circle_rounded, iconColor: AppColors.primaryGreenStart);
        Navigator.pop(context);
      } else {
        BonoboSoftToast.show(context, message: 'Erreur lors de l\'envoi.', icon: Icons.error_outline_rounded, iconColor: AppColors.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final textPrimary = isDark ? Colors.white : AppColors.textPrimary;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E2035) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Soumettre un média', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18, color: textPrimary)),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Ajoutez un flux RSS pour qu\'il soit indexé sur Bonobo.', style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white60 : AppColors.textSecondary)),
          const SizedBox(height: 24),
          _buildField(controller: _siteNameController, label: 'Nom du média', hint: 'Ex: Zoom Eco', icon: Icons.business_rounded, isDark: isDark),
          const SizedBox(height: 16),
          _buildField(controller: _feedUrlController, label: 'URL du Flux (RSS/JSON)', hint: 'https://monmedia.com/feed', icon: Icons.rss_feed_rounded, isDark: isDark),
          const SizedBox(height: 16),
          _buildField(controller: _contactEmailController, label: 'Email de contact', hint: 'contact@monmedia.com', icon: Icons.alternate_email_rounded, isDark: isDark),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Envoyer le média'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required String hint, required IconData icon, required bool isDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primaryGreen, size: 20),
            filled: true,
            fillColor: isDark ? const Color(0xFF141625) : Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)),
          ),
        ),
      ],
    );
  }
}

class MediaCertificationRequestModal extends ConsumerStatefulWidget {
  final Map<String, dynamic> media;
  const MediaCertificationRequestModal({super.key, required this.media});

  @override
  ConsumerState<MediaCertificationRequestModal> createState() =>
      _MediaCertificationRequestModalState();
}

class _MediaCertificationRequestModalState
    extends ConsumerState<MediaCertificationRequestModal> {
  String _selectedType = 'green'; // green | yellow
  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final service =
        JournalistApplicationService(token: ref.read(authProvider).token);
    final success = await service.submitCertificationRequest(
      mediaId: widget.media['id'].toString(),
      type: _selectedType,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        BonoboSoftToast.show(context,
            message: 'Demande de certification envoyée !',
            icon: Icons.check_circle_rounded,
            iconColor: AppColors.primaryGreenStart);
        Navigator.pop(context, true);
      } else {
        BonoboSoftToast.show(context,
            message: 'Erreur lors de l\'envoi de la demande.',
            icon: Icons.error_outline_rounded,
            iconColor: AppColors.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColors.textPrimary;
    final textSecondary = isDark ? Colors.white60 : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2035) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Certification de média',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: textPrimary)),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Demandez un badge pour ${widget.media['name']} pour renforcer votre crédibilité.',
            style: GoogleFonts.inter(fontSize: 13, color: textSecondary),
          ),
          const SizedBox(height: 24),
          _CertificationOption(
            title: 'Badge Vert (Partenaire)',
            subtitle: 'Pour les médias partenaires officiels de Bonobo.',
            icon: Icons.verified_user_rounded,
            color: AppColors.primaryGreenStart,
            isSelected: _selectedType == 'green',
            onTap: () => setState(() => _selectedType = 'green'),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _CertificationOption(
            title: 'Badge Jaune (Observateur)',
            subtitle: 'Pour les médias indépendants ou en cours d\'analyse.',
            icon: Icons.report_problem_rounded,
            color: Colors.amber,
            isSelected: _selectedType == 'yellow',
            onTap: () => setState(() => _selectedType = 'yellow'),
            isDark: isDark,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Soumettre ma demande'),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'L\'analyse prend généralement 2 à 3 heures.',
              style: GoogleFonts.inter(fontSize: 11, color: textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificationOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _CertificationOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : (isDark ? const Color(0xFF141625) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : (isDark ? Colors.white10 : Colors.grey.shade200),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? Colors.white : AppColors.textPrimary),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
