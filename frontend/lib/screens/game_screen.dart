import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../models/profile.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../widgets/profile_card.dart';
import 'result_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final CardSwiperController _controller = CardSwiperController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showResultFeedback(
    BuildContext context,
    bool isCorrect,
    Profile profile,
  ) {
    final realLabel =
        profile.type == ProfileType.linkedin ? 'LinkedIn' : 'Interpol';
    final post = profile.context;
    final reveal =
        (post != null && post.isNotEmpty) ? '$realLabel · $post' : realLabel;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1300),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              isCorrect ? AppConstants.successColor : AppConstants.errorColor,
          content: Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isCorrect ? 'Correct ! $reveal' : "Raté ! C'était $reveal",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  void _handleSwipe(BuildContext context, ProfileType answer) {
    final gameProvider = context.read<GameProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final session = gameProvider.currentSession;

    if (session == null || session.isFinished) return;

    final currentProfile = session.currentProfile;
    if (currentProfile == null) return;

    final isCorrect = currentProfile.type == answer;

    // Vibration feedback
    if (isCorrect) {
      settingsProvider.vibrateSuccess();
    } else {
      settingsProvider.vibrateError();
    }

    // Feedback visuel après chaque swipe (révèle la vraie réponse)
    _showResultFeedback(context, isCorrect, currentProfile);

    // Update game state
    gameProvider.answerQuestion(answer);

    // Check if game is finished
    if (gameProvider.currentSession?.isFinished == true) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ResultScreen()),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('LinkedIn ou Interpol'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          final session = gameProvider.currentSession;

          if (session == null) {
            return const Center(child: Text('Aucune session active'));
          }

          // Check if profiles are available
          if (session.profiles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun profil disponible',
                    style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Impossible de charger les données',
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Retour'),
                  ),
                ],
              ),
            );
          }

          final int remainingCards =
              session.profiles.length - session.currentIndex;
          final int numberOfCardsToDisplay = math.min(4, session.profiles.length);

          return SafeArea(
            child: Column(
              children: [
                // Header with score and progress
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
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
                            value:
                                '${session.profiles.length - session.currentIndex}',
                            icon: Icons.collections,
                            color: AppConstants.primaryColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: session.currentIndex / session.profiles.length,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppConstants.primaryColor,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                // Card swiper
                Expanded(
                  child: remainingCards == 0
                      ? const SizedBox.shrink()
                      : CardSwiper(
                          controller: _controller,
                          cardsCount: session.profiles.length,
                          numberOfCardsDisplayed: numberOfCardsToDisplay,
                          backCardOffset: const Offset(0, 40),
                          padding: const EdgeInsets.all(24.0),
                          allowedSwipeDirection:
                              const AllowedSwipeDirection.symmetric(
                                horizontal: true,
                              ),
                          isLoop: false,
                          onSwipe: (previousIndex, currentIndex, direction) {
                            ProfileType? answer;
                            if (direction == CardSwiperDirection.left) {
                              answer = ProfileType.interpol;
                            } else if (direction == CardSwiperDirection.right) {
                              answer = ProfileType.linkedin;
                            }

                            if (answer != null) {
                              _handleSwipe(context, answer);
                              return true;
                            }

                            return false;
                          },
                          cardBuilder:
                              (
                                context,
                                index,
                                percentThresholdX,
                                percentThresholdY,
                              ) {
                                return Align(
                                  alignment: .topCenter,
                                  child: ProfileCard(
                                    profile: session.profiles[index],
                                    horizontalOffsetPercentage:
                                        percentThresholdX,
                                  ),
                                );
                              },
                        ),
                ),
                // Buttons
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _AnswerButton(
                          label: 'Interpol',
                          color: AppConstants.secondaryColor,
                          icon: Icons.warning,
                          onPressed: () {
                            _handleSwipe(context, ProfileType.interpol);
                            _controller.swipe(.left);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _AnswerButton(
                          label: 'LinkedIn',
                          color: AppConstants.primaryColor,
                          icon: Icons.business_center,
                          onPressed: () {
                            _handleSwipe(context, ProfileType.linkedin);
                            _controller.swipe(.right);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppConstants.textColor,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  const _AnswerButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
