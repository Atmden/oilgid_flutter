import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oil_gid/features/garage/domain/entities/expense_category.dart';
import 'package:oil_gid/features/garage/presentation/providers/expense_categories_provider.dart';
import 'package:oil_gid/themes/app_colors.dart';

class CategoryPicker extends ConsumerWidget {
  final ExpenseCategory? selected;
  final ValueChanged<ExpenseCategory> onSelected;
  final VoidCallback? onManageCategories;

  const CategoryPicker({
    super.key,
    required this.selected,
    required this.onSelected,
    this.onManageCategories,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(expenseCategoriesProvider);

    return state.when(
      loading: () => const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Text(
        'Не удалось загрузить категории',
        style: const TextStyle(color: Colors.red, fontSize: 13),
      ),
      data: (categories) => _CategoryGrid(
        categories: categories,
        selected: selected,
        onSelected: onSelected,
        onManageCategories: onManageCategories,
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<ExpenseCategory> categories;
  final ExpenseCategory? selected;
  final ValueChanged<ExpenseCategory> onSelected;
  final VoidCallback? onManageCategories;

  const _CategoryGrid({
    required this.categories,
    required this.selected,
    required this.onSelected,
    this.onManageCategories,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Категория *',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            if (onManageCategories != null)
              GestureDetector(
                onTap: onManageCategories,
                child: const Text(
                  'Управление',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primarySoft,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((cat) {
            final isSelected = selected?.id == cat.id;
            return GestureDetector(
              onTap: () => onSelected(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? cat.color : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? cat.color : AppColors.border,
                    width: isSelected ? 0 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat.icon,
                      size: 16,
                      color: isSelected ? Colors.white : cat.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
