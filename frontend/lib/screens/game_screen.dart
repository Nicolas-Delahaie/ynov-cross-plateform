import 'dart:async';
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

  // Durée d'affichage du feedback (secondes) = durée du décompte
  static const int _feedbackSeconds = 3;

  // État du feedback centré affiché après chaque swipe
  bool _showFeedback = false;
  bool _feedbackCorrect = false;
  String _feedbackText = '';
  int _feedbackCountdown = 0;
  Timer? _feedbackTimer;

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Limite la longueur du texte affiché dans le feedback : certains délits
  /// Interpol sont des paragraphes juridiques entiers qui font déborder la
  /// popup. On coupe sur un mot pour rester lisible.
  static String _truncate(String text, {int maxLength = 140}) {
    if (text.length <= maxLength) return text;
    final cut = text.substring(0, maxLength);
    final lastSpace = cut.lastIndexOf(' ');
    return '${lastSpace > 0 ? cut.substring(0, lastSpace) : cut}…';
  }

  void _showResultFeedback(bool isCorrect, Profile profile) {
    final realLabel =
        profile.type == ProfileType.linkedin ? 'LinkedIn' : 'Interpol';
    // Nettoie le texte (les délits Interpol ont des retours à la ligne en vrac)
    final cleaned = profile.context?.replaceAll(RegExp(r'\s+'), ' ').trim();
    final post =
        (cleaned != null && cleaned.isNotEmpty) ? _truncate(cleaned) : null;
    final reveal =
        (post != null && post.isNotEmpty) ? '$realLabel · $post' : realLabel;

    _feedbackTimer?.cancel();
    setState(() {
      _showFeedback = true;
      _feedbackCorrect = isCorrect;
      _feedbackText = isCorrect ? 'Correct !\n$reveal' : "Raté !\nC'était $reveal";
      _feedbackCountdown = _feedbackSeconds;
    });

    // Décompte 3 -> 2 -> 1 -> disparition (le jeu enchaîne tout seul)
    _feedbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _feedbackCountdown--);
      if (_feedbackCountdown <= 0) {
        timer.cancel();
        setState(() => _showFeedback = false);
      }
    });
  }

  Widget _buildFeedbackOverlay() {
    final color = _feedbackCorrect
        ? AppConstants.successColor
        : AppConstants.errorColor;
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          child: Center(
            child: TweenAnimationBuilder<double>(
              key: ValueKey(_feedbackText),
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _feedbackCorrect ? Icons.check_circle : Icons.cancel,
                      color: Colors.white,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Text(
                          _feedbackText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Décompte : anneau qui se vide + nombre de secondes
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            key: ValueKey(_feedbackText),
                            tween: Tween(begin: 1.0, end: 0.0),
                            duration: const Duration(seconds: _feedbackSeconds),
                            builder: (context, value, _) =>
                                CircularProgressIndicator(
                              value: value,
                              strokeWidth: 4,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            '$_feedbackCountdown',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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

    // Feedback son + vibration
    if (isCorrect) {
      settingsProvider.vibrateSuccess();
      settingsProvider.playSuccess();
    } else {
      settingsProvider.vibrateError();
      settingsProvider.playError();
    }

    // Feedback visuel après chaque swipe (révèle la vraie réponse)
    _showResultFeedback(isCorrect, currentProfile);

    // Update game state
    gameProvider.answerQuestion(answer);

    if (gameProvider.currentSession?.isFinished == true) {
      // On laisse le décompte de la dernière carte se terminer avant l'écran final
      final navigator = Navigator.of(context);
      Future.delayed(const Duration(seconds: _feedbackSeconds), () {
        if (mounted) {
          navigator.pushReplacement(
            MaterialPageRoute(builder: (_) => const ResultScreen()),
          );
        }
      });
    }
  }

  /// Popup de confirmation avant d'abandonner la partie.
  Future<bool> _confirmQuit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter la partie ?'),
        content: const Text(
          'Ta progression sera perdue et la partie ne sera pas comptée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppConstants.errorColor,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Intercepte le retour (bouton ← ou geste système) en pleine partie.
  Future<void> _onBackAttempt(bool didPop) async {
    if (didPop) return;
    final shouldLeave = await _confirmQuit();
    if (!mounted || !shouldLeave) return;
    // Abandon : on vide la session (non comptée) puis on quitte
    context.read<GameProvider>().endGame();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _onBackAttempt(didPop),
      child: Scaffold(
      appBar: AppBar(
        title: const Text('LinkedIn ou Interpol'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          final session = gameProvider.currentSession;
          final colorScheme = Theme.of(context).colorScheme;

          if (session == null) {
            return const Center(child: Text('Aucune session active'));
          }

          if (session.profiles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun profil disponible',
                    style: TextStyle(fontSize: 20, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Impossible de charger les données',
                    style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.5)),
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

          final int numberOfCardsToDisplay =
              math.min(2, session.profiles.length);

          return SafeArea(
            child: Column(
              children: [
                // Header with score and progress
                Container(
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
                          valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                // Card swiper
                // Reste toujours monté même une fois la dernière carte
                // répondue : le retirer pendant que le swiper termine son
                // animation interne provoque un setState() post-dispose
                // (bug connu de flutter_card_swiper).
                Expanded(
                  child: CardSwiper(
                    controller: _controller,
                    cardsCount: session.profiles.length,
                    numberOfCardsDisplayed: numberOfCardsToDisplay,
                    backCardOffset: const Offset(0, 40),
                    padding: const EdgeInsets.all(24.0),
                    allowedSwipeDirection:
                        const AllowedSwipeDirection.symmetric(horizontal: true),
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
                          return ProfileCard(
                            profile: session.profiles[index],
                            horizontalOffsetPercentage: percentThresholdX,
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
                          // Déclenche juste l'animation -> onSwipe fait le reste
                          onPressed: () =>
                              _controller.swipe(CardSwiperDirection.left),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _AnswerButton(
                          label: 'LinkedIn',
                          color: AppConstants.primaryColor,
                          icon: Icons.business_center,
                          // Déclenche juste l'animation -> onSwipe fait le reste
                          onPressed: () =>
                              _controller.swipe(CardSwiperDirection.right),
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
          if (_showFeedback) _buildFeedbackOverlay(),
        ],
      ),
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
