import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../utils/constants.dart';

class ProfileCard extends StatelessWidget {
  final Profile profile;
  final int horizontalOffsetPercentage;

  const ProfileCard({
    super.key,
    required this.profile,
    this.horizontalOffsetPercentage = 0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDragging = horizontalOffsetPercentage != 0;
    final bool isDraggingLeft = horizontalOffsetPercentage < 0;
    final Color directionColor = isDraggingLeft
        ? AppConstants.secondaryColor
        : AppConstants.primaryColor;
    final String labelText = isDraggingLeft ? 'INTERPOL' : 'LINKEDIN';
    final double progress =
        (horizontalOffsetPercentage.abs() / 100).clamp(0.0, 1.0);

    // Size the image at 28% of screen height so it always fits the card area
    // regardless of what constraints CardSwiper propagates.
    final double imageSize =
        (MediaQuery.of(context).size.height * 0.28).clamp(80.0, 250.0);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Card content
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.grey[100]!],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Profile image
                  Container(
                    width: imageSize,
                    height: imageSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppConstants.primaryColor,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        profile.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.person,
                              size: imageSize * 0.4,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[300],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Swipe ou choisissez',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // Color overlay
            if (isDragging)
              Positioned.fill(
                child: Container(
                  color: directionColor.withValues(alpha: progress * 0.4),
                ),
              ),
            // Direction label
            if (isDragging)
              Positioned.fill(
                child: Center(
                  child: Opacity(
                    opacity: progress,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: directionColor, width: 3),
                        borderRadius: BorderRadius.circular(12),
                        color: directionColor.withValues(alpha: 0.8),
                      ),
                      child: Text(
                        labelText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
