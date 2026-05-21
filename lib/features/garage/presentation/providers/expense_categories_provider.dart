import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oil_gid/core/api/app_api.dart';
import 'package:oil_gid/features/garage/domain/entities/expense_category.dart';

final expenseCategoriesProvider =
    AsyncNotifierProvider<ExpenseCategoriesNotifier, List<ExpenseCategory>>(
  ExpenseCategoriesNotifier.new,
);

class ExpenseCategoriesNotifier
    extends AsyncNotifier<List<ExpenseCategory>> {
  @override
  Future<List<ExpenseCategory>> build() {
    return AppApi().expenseCategoryApi.getCategories();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => AppApi().expenseCategoryApi.getCategories(),
    );
  }

  Future<bool> create(Map<String, dynamic> data) async {
    try {
      await AppApi().expenseCategoryApi.createCategory(data);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> edit(int id, Map<String, dynamic> data) async {
    try {
      await AppApi().expenseCategoryApi.updateCategory(id, data);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await AppApi().expenseCategoryApi.deleteCategory(id);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }
}
