import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../models/profile.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../widgets/answer_buttons_row.dart';
import '../widgets/game_card_swiper.dart';
import '../widgets/game_feedback_overlay.dart';
import '../widgets/game_header.dart';
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
                  return _NoProfilesView(colorScheme: colorScheme);
                }

                return SafeArea(
                  child: Column(
                    children: [
                      GameHeader(session: session),
                      Expanded(
                        child: GameCardSwiper(
                          controller: _controller,
                          session: session,
                          onAnswer: (answer) => _handleSwipe(context, answer),
                        ),
                      ),
                      AnswerButtonsRow(
                        // Déclenche juste l'animation -> onSwipe fait le reste
                        onInterpol: () =>
                            _controller.swipe(CardSwiperDirection.left),
                        onLinkedin: () =>
                            _controller.swipe(CardSwiperDirection.right),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (_showFeedback)
              GameFeedbackOverlay(
                isCorrect: _feedbackCorrect,
                text: _feedbackText,
                countdown: _feedbackCountdown,
                feedbackSeconds: _feedbackSeconds,
              ),
          ],
        ),
      ),
    );
  }
}

class _NoProfilesView extends StatelessWidget {
  final ColorScheme colorScheme;

  const _NoProfilesView({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun profil disponible',
            style: TextStyle(
              fontSize: 20,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Impossible de charger les données',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
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
}
