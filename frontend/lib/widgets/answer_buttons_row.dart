import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Les deux boutons de réponse ("Interpol" / "LinkedIn") sous le swiper.
class AnswerButtonsRow extends StatelessWidget {
  final VoidCallback onInterpol;
  final VoidCallback onLinkedin;

  const AnswerButtonsRow({
    super.key,
    required this.onInterpol,
    required this.onLinkedin,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Expanded(
            child: _AnswerButton(
              label: 'Interpol',
              color: AppConstants.secondaryColor,
              icon: Icons.warning,
              onPressed: onInterpol,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _AnswerButton(
              label: 'LinkedIn',
              color: AppConstants.primaryColor,
              icon: Icons.business_center,
              onPressed: onLinkedin,
            ),
          ),
        ],
      ),
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
