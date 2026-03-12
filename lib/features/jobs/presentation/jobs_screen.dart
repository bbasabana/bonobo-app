import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/bonobo_app_bar.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../domain/job_offer.dart';

class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BonoboAppBar(title: 'Offres d\'Emploi'),
      body: Column(
        children: [
          const OfflineBanner(),
          // Partner header
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.backgroundDark, Color(0xFF2A2B40)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.work_rounded, size: 32, color: Colors.white70),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emplois RDC',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'En partenariat avec Médias Congo',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _JobsList(),
          ),
        ],
      ),
    );
  }
}

class _JobsList extends StatelessWidget {
  static final _mockJobs = [
    JobOffer(
      id: '1',
      title: 'Développeur Mobile Flutter',
      employer: 'Airtel Congo',
      description:
          'Nous recherchons un développeur Flutter expérimenté pour rejoindre notre équipe digitale à Kinshasa.',
      deadline: '31 mars 2025',
      sourceUrl: 'https://mediascongo.net',
      fetchedAt: DateTime.now(),
    ),
    JobOffer(
      id: '2',
      title: 'Journaliste Reporter',
      employer: 'Radio Okapi',
      description:
          'Radio Okapi recherche un journaliste reporter terrain pour ses bureaux de Kinshasa et Goma.',
      deadline: '15 avril 2025',
      sourceUrl: 'https://mediascongo.net',
      fetchedAt: DateTime.now(),
    ),
    JobOffer(
      id: '3',
      title: 'Responsable Communication',
      employer: 'UNICEF RDC',
      description:
          'UNICEF Congo cherche un responsable communication pour ses programmes humanitaires.',
      deadline: '20 avril 2025',
      sourceUrl: 'https://mediascongo.net',
      fetchedAt: DateTime.now(),
    ),
    JobOffer(
      id: '4',
      title: 'Comptable Senior',
      employer: 'Banque Commerciale du Congo',
      description: 'La BCC recrute un comptable senior avec minimum 5 ans d\'expérience.',
      deadline: '10 avril 2025',
      sourceUrl: 'https://mediascongo.net',
      fetchedAt: DateTime.now(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _mockJobs.length,
      itemBuilder: (context, index) => _JobCard(job: _mockJobs[index]),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobOffer job;

  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2035) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.work_rounded, size: 20, color: Colors.white70),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        job.employer,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              job.description,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (job.deadline != null) ...[
                  Icon(Icons.calendar_today_rounded,
                      size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Délai: ${job.deadline}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.tryParse(job.sourceUrl);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Postuler',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
