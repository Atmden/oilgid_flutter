import 'package:flutter/material.dart';
import 'package:oil_gid/themes/app_colors.dart';

class PermissionIntroScaffold extends StatelessWidget {
  const PermissionIntroScaffold({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onAllow,
    required this.onSkip,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onAllow;
  final VoidCallback onSkip;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Icon(icon, size: 96, color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onAllow,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Разрешить'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: isLoading ? null : onSkip,
                child: const Text('Не сейчас'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
