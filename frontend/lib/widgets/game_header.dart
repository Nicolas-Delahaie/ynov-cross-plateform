import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../utils/constants.dart';

/// Bandeau en haut de l'écran de jeu : score, série, cartes restantes et
/// barre de progression de la partie en cours.
class GameHeader extends StatelessWidget {
  final GameSession session;

  const GameHeader({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      color: colorScheme.surface,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ScoreItem(
                label: 'Score',
                value: session.correctAnswers.toString(),
                icon: Icons.star,
                color: Colors.amber,
              ),
              _ScoreItem(
                label: 'Série',
                value: session.currentStreak.toString(),
                icon: Icons.local_fire_department,
                color: Colors.orange,
              ),
              _ScoreItem(
                label: 'Restant',
                value: '${session.profiles.length - session.currentIndex}',
                icon: Icons.collections,
                color: AppConstants.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: session.currentIndex / session.profiles.length,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppConstants.primaryColor,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ScoreItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
