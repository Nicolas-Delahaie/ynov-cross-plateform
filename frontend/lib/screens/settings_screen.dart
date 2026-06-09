import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _SettingCard(
                title: 'Mode sombre',
                subtitle: 'Thème sombre pour l\'interface',
                icon: Icons.dark_mode,
                child: Switch(
                  value: settingsProvider.isDarkMode,
                  onChanged: settingsProvider.setDarkMode,
                  activeThumbColor: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              _SettingCard(
                title: 'Sons',
                subtitle: 'Activer les effets sonores',
                icon: Icons.volume_up,
                child: Switch(
                  value: settingsProvider.soundEnabled,
                  onChanged: settingsProvider.setSoundEnabled,
                  activeThumbColor: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              _SettingCard(
                title: 'Vibrations',
                subtitle: 'Retour haptique lors des réponses',
                icon: Icons.vibration,
                child: Switch(
                  value: settingsProvider.vibrationEnabled,
                  onChanged: (value) async {
                    await settingsProvider.setVibrationEnabled(value);
                    if (value) settingsProvider.vibrateTap();
                  },
                  activeThumbColor: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Difficulté',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _DifficultyOption(
                label: 'Facile',
                description: '10 photos par partie',
                value: AppConstants.easyProfilesPerGame,
                groupValue: settingsProvider.difficulty,
                onChanged: (value) {
                  if (value != null) settingsProvider.setDifficulty(value);
                },
              ),
              const SizedBox(height: 12),
              _DifficultyOption(
                label: 'Normal',
                description: '20 photos par partie',
                value: AppConstants.defaultProfilesPerGame,
                groupValue: settingsProvider.difficulty,
                onChanged: (value) {
                  if (value != null) settingsProvider.setDifficulty(value);
                },
              ),
              const SizedBox(height: 12),
              _DifficultyOption(
                label: 'Difficile',
                description: '30 photos par partie',
                value: AppConstants.hardProfilesPerGame,
                groupValue: settingsProvider.difficulty,
                onChanged: (value) {
                  if (value != null) settingsProvider.setDifficulty(value);
                },
              ),
              const SizedBox(height: 32),
              _SettingCard(
                title: 'À propos',
                subtitle: 'LinkedIn ou Interpol v1.0.0',
                icon: Icons.info_outline,
                child: const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _SettingCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppConstants.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _DifficultyOption extends StatelessWidget {
  final String label;
  final String description;
  final int value;
  final int groupValue;
  final ValueChanged<int?> onChanged;

  const _DifficultyOption({
    required this.label,
    required this.description,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = value == groupValue;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        context.read<SettingsProvider>().vibrateTap();
        onChanged(value);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppConstants.primaryColor : colorScheme.outline,
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Radio<int>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: AppConstants.primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
