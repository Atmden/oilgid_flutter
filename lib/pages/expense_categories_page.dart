import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oil_gid/features/garage/domain/entities/expense_category.dart';
import 'package:oil_gid/features/garage/domain/entities/icon_registry.dart';
import 'package:oil_gid/features/garage/presentation/providers/expense_categories_provider.dart';
import 'package:oil_gid/includes/main_app_bar.dart';
import 'package:oil_gid/themes/app_colors.dart';

class ExpenseCategoriesPage extends ConsumerWidget {
  const ExpenseCategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(expenseCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MainAppBar(title: 'Категории расходов'),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(expenseCategoriesProvider.notifier).refresh(),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
        ),
        data: (categories) => _CategoriesList(categories: categories),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryForm(context, ref, null),
        backgroundColor: AppColors.primarySoft,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
    );
  }

  static void _showCategoryForm(
    BuildContext context,
    WidgetRef ref,
    ExpenseCategory? existing,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryFormSheet(existing: existing, ref: ref),
    );
  }
}

class _CategoriesList extends ConsumerWidget {
  final List<ExpenseCategory> categories;

  const _CategoriesList({required this.categories});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categories.isEmpty) {
      return const Center(
        child: Text(
          'Нет категорий. Добавьте первую.',
          style: TextStyle(color: Colors.black45),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final cat = categories[index];
        return _CategoryTile(
          category: cat,
          onEdit: () =>
              ExpenseCategoriesPage._showCategoryForm(context, ref, cat),
          onDelete: () => _confirmDelete(context, ref, cat),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ExpenseCategory cat,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить категорию?'),
        content: Text(
          'Записи с категорией "${cat.name}" останутся, но категория будет удалена.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final ok =
        await ref.read(expenseCategoriesProvider.notifier).delete(cat.id);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось удалить категорию.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _CategoryTile extends StatelessWidget {
  final ExpenseCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: category.color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(category.icon, color: category.color, size: 20),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: category.isDefault
            ? const Text(
                'По умолчанию',
                style: TextStyle(fontSize: 12, color: Colors.black38),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
              color: Colors.black45,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete,
              color: Colors.redAccent,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFormSheet extends StatefulWidget {
  final ExpenseCategory? existing;
  final WidgetRef ref;

  const _CategoryFormSheet({required this.existing, required this.ref});

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  late final TextEditingController _nameController;
  late String _selectedIconKey;
  late Color _selectedColor;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController =
        TextEditingController(text: existing?.name ?? '');
    _selectedIconKey = existing?.iconKey ?? 'more_horiz';
    _selectedColor = existing?.color ?? const Color(0xFF546E7A);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Введите название.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final data = {
      'name': name,
      'icon_key': _selectedIconKey,
      'color_hex': _colorToHex(_selectedColor),
    };

    final notifier = widget.ref.read(expenseCategoriesProvider.notifier);
    bool ok;
    if (widget.existing != null) {
      ok = await notifier.edit(widget.existing!.id, data);
    } else {
      ok = await notifier.create(data);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _error = 'Не удалось сохранить. Попробуйте снова.');
    }
  }

  Future<void> _pickColor() async {
    Color tempColor = _selectedColor;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выберите цвет'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: tempColor,
            onColorChanged: (c) => tempColor = c,
            enableAlpha: false,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _selectedColor = tempColor);
              Navigator.pop(ctx);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                isEdit ? 'Редактировать категорию' : 'Новая категория',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Название *',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Color(0xFFF9F9F9),
            ),
          ),
          const SizedBox(height: 16),

          // Выбор цвета
          Row(
            children: [
              const Text('Цвет:', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _pickColor,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _pickColor,
                child: const Text('Изменить'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Выбор иконки
          const Text('Иконка:', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: iconRegistry.length,
              itemBuilder: (context, index) {
                final entry = iconRegistry.entries.elementAt(index);
                final isSelected = entry.key == _selectedIconKey;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedIconKey = entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _selectedColor.withOpacity(0.15)
                          : const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? _selectedColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      entry.value,
                      size: 22,
                      color: isSelected ? _selectedColor : Colors.black54,
                    ),
                  ),
                );
              },
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],

          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primarySoft,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(isEdit ? 'Сохранить' : 'Создать'),
          ),
        ],
      ),
    );
  }
}
