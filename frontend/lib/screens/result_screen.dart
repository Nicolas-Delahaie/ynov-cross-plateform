import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:share_plus/share_plus.dart';
import '../models/game_session.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/statistics_provider.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameProvider = context.read<GameProvider>();
      final settingsProvider = context.read<SettingsProvider>();
      final session = gameProvider.currentSession;
      if (session != null && session.accuracy >= 0.7) {
        _confettiController.play();
        settingsProvider.vibrateCelebration();
      } else {
        settingsProvider.vibrateIfEnabled(duration: 100);
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _shareScore(GameSession session) async {
    final accuracy = (session.accuracy * 100).toStringAsFixed(0);
    await SharePlus.instance.share(
      ShareParams(
        text: 'J\'ai fait ${session.correctAnswers}/${session.profiles.length} '
            '($accuracy% de réussite) sur LinkedIn ou Interpol ! 🕵️‍♂️💼 '
            'Sauras-tu faire mieux ?',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Consumer2<GameProvider, StatisticsProvider>(
              builder: (context, gameProvider, statisticsProvider, child) {
                final session = gameProvider.currentSession;
                final statistics = statisticsProvider.statistics;
                final colorScheme = Theme.of(context).colorScheme;

                if (session == null) {
                  return const Center(child: Text('Aucune session'));
                }

                final accuracy = (session.accuracy * 100).toStringAsFixed(1);
                final isNewBestScore = session.correctAnswers == statistics.bestScore &&
                    statistics.totalGamesPlayed > 1;

                return Column(
                  children: [
                    // Scrollable content — never overflows regardless of screen size
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                        child: Column(
                          children: [
                            // Title
                            Text(
                              'Partie terminée !',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Score
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.emoji_events,
                                    size: 80,
                                    color: session.accuracy >= 0.7
                                        ? Colors.amber
                                        : Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '${session.correctAnswers}/${session.profiles.length}',
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$accuracy% de réussite',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  if (isNewBestScore) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.new_releases,
                                            color: Colors.amber[700],
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Nouveau record !',
                                            style: TextStyle(
                                              color: Colors.amber[700],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Statistics
                            _StatRow(
                              label: 'Meilleure série',
                              value: session.bestStreak.toString(),
                              icon: Icons.local_fire_department,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 16),
                            _StatRow(
                              label: 'Durée',
                              value: _formatDuration(session.duration),
                              icon: Icons.timer,
                              color: AppConstants.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Buttons always visible at bottom
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () async {
                                final settingsProvider =
                                    context.read<SettingsProvider>();
                                settingsProvider.vibrateTap();
                                await gameProvider.startNewGame(
                                  profilesCount: settingsProvider.difficulty,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.replay),
                                  SizedBox(width: 12),
                                  Text(
                                    'Rejouer',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: () {
                                context.read<SettingsProvider>().vibrateTap();
                                gameProvider.endGame();
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HomeScreen(),
                                  ),
                                  (route) => false,
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.onSurface,
                                side: BorderSide(
                                  color: colorScheme.onSurface,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Retour au menu',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              context.read<SettingsProvider>().vibrateTap();
                              _shareScore(session);
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Partager mon score'),
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              maxBlastForce: 20,
              minBlastForce: 5,
              gravity: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
