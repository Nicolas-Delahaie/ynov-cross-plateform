import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../models/game_session.dart';
import '../models/profile.dart';
import 'profile_card.dart';

/// Pile de cartes swipables de l'écran de jeu. Reste toujours monté même
/// une fois la dernière carte répondue : le retirer pendant que le swiper
/// termine son animation interne provoque un setState() post-dispose
/// (bug connu de flutter_card_swiper).
class GameCardSwiper extends StatelessWidget {
  final CardSwiperController controller;
  final GameSession session;
  final void Function(ProfileType answer) onAnswer;

  const GameCardSwiper({
    super.key,
    required this.controller,
    required this.session,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final numberOfCardsToDisplay = math.min(2, session.profiles.length);

    return CardSwiper(
      controller: controller,
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
          onAnswer(answer);
          return true;
        }

        return false;
      },
      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
        return ProfileCard(
          profile: session.profiles[index],
          horizontalOffsetPercentage: percentThresholdX,
        );
      },
    );
  }
}
