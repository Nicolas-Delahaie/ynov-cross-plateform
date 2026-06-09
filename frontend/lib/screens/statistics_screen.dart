import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/statistics_provider.dart';
import '../models/profile.dart';
import '../utils/constants.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<StatisticsProvider>(
        builder: (context, statisticsProvider, child) {
          final statistics = statisticsProvider.statistics;
          final colorScheme = Theme.of(context).colorScheme;

          if (statistics.totalGamesPlayed == 0) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 80, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune partie jouée',
                    style: TextStyle(fontSize: 20, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Jouez une partie pour voir vos stats !',
                    style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            );
          }

          final accuracy = (statistics.overallAccuracy * 100).toStringAsFixed(1);
          final linkedinErrors = statistics.errorsByType[ProfileType.linkedin] ?? 0;
          final interpolErrors = statistics.errorsByType[ProfileType.interpol] ?? 0;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _StatCard(
                title: 'Parties jouées',
                value: statistics.totalGamesPlayed.toString(),
                icon: Icons.sports_esports,
                color: AppConstants.primaryColor,
              ),
              const SizedBox(height: 16),
              _StatCard(
                title: 'Meilleur score',
                value: statistics.bestScore.toString(),
                icon: Icons.emoji_events,
                color: Colors.amber,
              ),
              const SizedBox(height: 16),
              _StatCard(
                title: 'Meilleure série',
                value: statistics.bestStreak.toString(),
                icon: Icons.local_fire_department,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              _StatCard(
                title: 'Taux de réussite global',
                value: '$accuracy%',
                icon: Icons.trending_up,
                color: AppConstants.successColor,
              ),
              const SizedBox(height: 32),
              Text(
                'Répartition des erreurs',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _ErrorRow(
                      label: 'LinkedIn pris pour Interpol',
                      value: linkedinErrors,
                      color: AppConstants.primaryColor,
                    ),
                    const SizedBox(height: 16),
                    _ErrorRow(
                      label: 'Interpol pris pour LinkedIn',
                      value: interpolErrors,
                      color: AppConstants.secondaryColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    _showResetDialog(context, statisticsProvider);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConstants.errorColor,
                    side: BorderSide(color: AppConstants.errorColor, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 12),
                      Text(
                        'Réinitialiser les statistiques',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showResetDialog(BuildContext context, StatisticsProvider statisticsProvider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Réinitialiser les statistiques'),
          content: const Text(
            'Êtes-vous sûr de vouloir supprimer toutes vos statistiques ? Cette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                statisticsProvider.reset();
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Statistiques réinitialisées')),
                );
              },
              child: Text(
                'Réinitialiser',
                style: TextStyle(color: AppConstants.errorColor),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _ErrorRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
          ),
        ),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
