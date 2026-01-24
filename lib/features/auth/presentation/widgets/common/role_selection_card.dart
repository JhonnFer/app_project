import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class RoleSelectionCard extends StatelessWidget {
  final String roleName;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const RoleSelectionCard({
    Key? key,
    required this.roleName,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isSelected ? 4 : 0,
        color: isSelected ? AppColors.primaryLight.withValues(alpha: 0.1) : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.grey200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                icon,
                size: 48,
                color: isSelected ? AppColors.primary : AppColors.grey400,
              ),
              const SizedBox(height: 12),
              Text(
                roleName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Seleccionado',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.white,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
