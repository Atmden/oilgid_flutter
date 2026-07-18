import 'package:flutter/foundation.dart';
import 'package:oil_gid/core/api/init_token_generator.dart';
import 'package:oil_gid/core/storage/token_storage.dart';

import '../../features/car_marks/data/datasources/car_mark_api.dart';
import '../../features/car_models/data/datasources/car_model_api.dart';
import '../../features/car_generations/data/datasources/car_generation_api.dart';
import '../../features/car_configurations/data/datasources/car_configuration_api.dart';
import '../../features/car_modifications/data/datasources/car_modification_api.dart';
import '../../features/garage/data/datasources/expense_category_api.dart';
import '../../features/garage/data/datasources/garage_api.dart';
import '../../features/oils/data/datasources/oil_api.dart';
import '../../features/shops/data/datasource/shop_model_api.dart';
import '../../features/subscription/data/datasources/subscription_datasource.dart';
import 'dio_client.dart';
import 'endpoints.dart';

class AppInitException implements Exception {
  final String message;
  final int? statusCode;
  final Object? details;

  const AppInitException(this.message, {this.statusCode, this.details});

  @override
  String toString() {
    final codePart = statusCode == null ? '' : ' statusCode=$statusCode';
    return 'AppInitException($message$codePart)';
  }
}

class AppApi {
  final _dio = DioClient().dio;

  late final CarMarkApi carMarkApi = CarMarkApi(_dio);
  late final CarModelApi carModelApi = CarModelApi(_dio);
  late final CarGenerationApi carGenerationApi = CarGenerationApi(_dio);
  late final CarConfigurationApi carConfigurationApi = CarConfigurationApi(
    _dio,
  );
  late final CarModificationApi carModificationApi = CarModificationApi(_dio);
  late final OilApi oilApi = OilApi(_dio);
  late final ShopModelApi shopModelApi = ShopModelApi(_dio);
  late final GarageApi garageApi = GarageApi(_dio);
  late final ExpenseCategoryApi expenseCategoryApi = ExpenseCategoryApi(_dio);
  late final SubscriptionDatasource subscriptionApi = SubscriptionDatasource(_dio);

  Future<Map<String, dynamic>> getConfig() async {
    final response = await _dio.get(Endpoints.appConfig);
    return response.data;
  }

  Future<void> initApp() async {
    final appToken = await TokenStorage().getAppToken();
    if (appToken != null && appToken.trim().isNotEmpty) {
      return;
    }

    final data = await InitTokenGenerator.generate();
    final response = await _dio.post(Endpoints.appInit, data: data);

    if (response.statusCode == null || response.statusCode! >= 400) {
      throw AppInitException(
        'initApp request failed',
        statusCode: response.statusCode,
        details: response.data,
      );
    }

    final body = response.data;
    if (body is! Map) {
      throw AppInitException(
        'initApp response has invalid body type',
        statusCode: response.statusCode,
        details: body,
      );
    }

    final tokenRaw = body['token'];
    if (tokenRaw is! String || tokenRaw.trim().isEmpty) {
      throw AppInitException(
        'initApp response does not contain a valid token',
        statusCode: response.statusCode,
        details: body,
      );
    }

    await TokenStorage().saveAppToken(tokenRaw);
  }

  Future<String> getPrivacyPolicy() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/app/privacy-policy',
    );

    return response.data?['data'] as String? ?? '';
  }
  
  Future<Map<String, dynamic>> addCarRequest(Map<String, dynamic> data) async {
    final response = await _dio.post(Endpoints.addCarRequest, data: data);
    return response.data;
  }

  Future<bool> registerDeviceToken({
    required String token,
    required String platform,
    double? lat,
    double? lng,
  }) async {
    final data = {
      'token': token,
      'platform': platform,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };
    debugPrint('PUSH: POST ${Endpoints.deviceTokens} $data');
    try {
      final response = await _dio.post(Endpoints.deviceTokens, data: data);
      debugPrint(
        'PUSH: response ${response.statusCode} ${response.data}',
      );
      return response.statusCode != null && response.statusCode! < 400;
    } catch (e) {
      debugPrint('PUSH: request failed: $e');
      rethrow;
    }
  }
}
