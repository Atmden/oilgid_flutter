import 'package:dio/dio.dart';
import '../../../../core/api/endpoints.dart';
import '../../domain/entities/expense_category.dart';
import '../models/expense_category_model.dart';

class ExpenseCategoryApi {
  final Dio _dio;

  ExpenseCategoryApi(this._dio);

  Future<List<ExpenseCategory>> getCategories() async {
    final response = await _dio.get(Endpoints.expenseCategories);
    final body = response.data;
    if (body is! Map) return [];
    if (body['success'] == false) {
      throw Exception(_msg(body, 'Не удалось загрузить категории.'));
    }
    final list = body['data'];
    if (list is! List) return [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ExpenseCategoryModel.fromJson)
        .toList();
  }

  Future<ExpenseCategory> createCategory(Map<String, dynamic> data) async {
    final response = await _dio.post(Endpoints.expenseCategories, data: data);
    return _parse(response.data, 'Не удалось создать категорию.');
  }

  Future<ExpenseCategory> updateCategory(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch(
      Endpoints.expenseCategory.replaceAll('{id}', id.toString()),
      data: data,
    );
    return _parse(response.data, 'Не удалось обновить категорию.');
  }

  Future<void> deleteCategory(int id) async {
    final response = await _dio.delete(
      Endpoints.expenseCategory.replaceAll('{id}', id.toString()),
    );
    final body = response.data;
    if (body is Map && body['success'] == false) {
      throw Exception(_msg(body, 'Не удалось удалить категорию.'));
    }
  }

  ExpenseCategory _parse(dynamic responseData, String fallbackMsg) {
    if (responseData is! Map) throw Exception('Некорректный ответ сервера.');
    if (responseData['success'] == false) {
      throw Exception(_msg(responseData, fallbackMsg));
    }
    final data = responseData['data'];
    if (data is! Map<String, dynamic>) throw Exception('Некорректный ответ сервера.');
    return ExpenseCategoryModel.fromJson(data);
  }

  String _msg(Map body, String fallback) {
    final m = body['message'];
    return (m is String && m.trim().isNotEmpty) ? m.trim() : fallback;
  }
}
