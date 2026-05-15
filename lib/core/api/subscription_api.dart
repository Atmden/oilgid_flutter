import 'package:oil_gid/core/api/dio_client.dart';
import 'package:oil_gid/core/api/endpoints.dart';

class SubscriptionApi {
  final _dio = DioClient().dio;

  Future<List<String>> getEntitlements() async {
    final response = await _dio.get(Endpoints.subscriptionStatus);
    final body = response.data;
    if (body is! Map) return [];
    if (body['success'] == false) return [];
    final data = body['data'];
    if (data is! Map) return [];
    final entitlements = data['entitlements'];
    if (entitlements is List) {
      return entitlements.whereType<String>().toList();
    }
    return [];
  }

  Future<bool> hasEntitlement(String key) async {
    final list = await getEntitlements();
    return list.contains(key);
  }
}
