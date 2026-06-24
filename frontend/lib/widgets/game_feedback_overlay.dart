import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Popup centrée affichée après chaque swipe, révélant si la réponse était
/// correcte, avec un décompte avant que le jeu n'enchaîne tout seul.
class GameFeedbackOverlay extends StatelessWidget {
  final bool isCorrect;
  final String text;
  final int countdown;
  final int feedbackSeconds;

  const GameFeedbackOverlay({
    super.key,
    required this.isCorrect,
    required this.text,
    required this.countdown,
    required this.feedbackSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isCorrect ? AppConstants.successColor : AppConstants.errorColor;
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          child: Center(
            child: TweenAnimationBuilder<double>(
              key: ValueKey(text),
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
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: Colors.white,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Text(
                          text,
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
                            key: ValueKey(text),
                            tween: Tween(begin: 1.0, end: 0.0),
                            duration: Duration(seconds: feedbackSeconds),
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
                            '$countdown',
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
}
