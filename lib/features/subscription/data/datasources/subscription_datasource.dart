import 'package:dio/dio.dart';
import '../../../../core/api/endpoints.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/subscription_status.dart';
import '../models/subscription_plan_model.dart';
import '../models/subscription_status_model.dart';

class SubscriptionDatasource {
  final Dio _dio;

  SubscriptionDatasource(this._dio);

  Future<List<SubscriptionPlan>> getPlans() async {
    final response = await _dio.get(Endpoints.subscriptionPlans);
    final body = response.data;
    if (body is! Map) return [];
    if (body['success'] == false) {
      throw Exception(_msg(body, 'Не удалось загрузить тарифы.'));
    }
    final list = body['data'];
    if (list is! List) return [];
    return list
        .whereType<Map<String, dynamic>>()
        .map<SubscriptionPlan>(SubscriptionPlanModel.fromJson)
        .toList();
  }

  Future<SubscriptionStatus> getStatus() async {
    final response = await _dio.get(Endpoints.subscriptionStatus);
    final body = response.data;
    if (body is! Map) throw Exception('Некорректный ответ сервера.');
    if (body['success'] == false) {
      throw Exception(_msg(body, 'Не удалось получить статус подписки.'));
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      return const SubscriptionStatusModel(isActive: false, entitlements: []);
    }
    return SubscriptionStatusModel.fromJson(data);
  }

  /// [platform] — берётся из [SubscriptionPlan.platformKey]: "ios" или "android"
  Future<SubscriptionStatus> validatePurchase({
    required String platform,
    required String productId,
    String? transactionId,
    String? purchaseToken,
  }) async {
    final response = await _dio.post(
      Endpoints.subscriptionValidatePurchase,
      data: {
        'platform': platform,
        'product_id': productId,
        if (transactionId != null) 'transaction_id': transactionId,
        if (purchaseToken != null) 'purchase_token': purchaseToken,
      },
    );
    final body = response.data;
    _assertSuccess(response.statusCode, body, 'Не удалось активировать подписку.');
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return SubscriptionStatusModel.fromJson(data);
    }
    return getStatus();
  }

  Future<SubscriptionStatus> restore({
    required String platform,
    List<String> transactionIds = const [],
    List<String> purchaseTokens = const [],
  }) async {
    final response = await _dio.post(
      Endpoints.subscriptionRestore,
      data: {
        'platform': platform,
        if (transactionIds.isNotEmpty) 'transaction_ids': transactionIds,
        if (purchaseTokens.isNotEmpty) 'purchase_tokens': purchaseTokens,
      },
    );
    final body = response.data;
    _assertSuccess(response.statusCode, body, 'Не удалось восстановить подписку.');
    return getStatus();
  }

  void _assertSuccess(int? statusCode, dynamic body, String fallback) {
    // HTTP-ошибка (500, 422 и т.д.) — бэкенд может не вернуть success:false
    if (statusCode != null && statusCode >= 400) {
      final msg = body is Map ? _msg(body, fallback) : fallback;
      throw Exception('[$statusCode] $msg');
    }
    if (body is! Map) throw Exception('Некорректный ответ сервера.');
    if (body['success'] == false) {
      throw Exception(_msg(body, fallback));
    }
  }

  String _msg(Map body, String fallback) {
    final message = body['message'];
    if (message is String && message.trim().isNotEmpty) return message.trim();
    return fallback;
  }
}
