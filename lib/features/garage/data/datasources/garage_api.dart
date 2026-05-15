import 'package:dio/dio.dart';
import '../../../../core/api/endpoints.dart';
import '../../domain/entities/attachment.dart';
import '../../domain/entities/service_record.dart';
import '../../domain/entities/user_car.dart';
import '../models/service_record_model.dart';
import '../models/user_car_model.dart';

class GarageApi {
  final Dio _dio;

  GarageApi(this._dio);

  // ── Cars ────────────────────────────────────────────────────────────────────

  Future<List<UserCar>> getCars() async {
    final response = await _dio.get(Endpoints.garageCars);
    final data = response.data;
    if (data is! Map) return [];
    if (data['success'] == false) {
      throw Exception(_extractMessage(data, 'Не удалось загрузить список автомобилей.'));
    }
    final list = data['data'];
    if (list is! List) return [];
    return list.whereType<Map<String, dynamic>>().map(UserCarModel.fromJson).toList();
  }

  Future<UserCar> getCar(int id) async {
    final response = await _dio.get(
      Endpoints.garageCar.replaceAll('{id}', id.toString()),
    );
    return _parseCarResponse(response.data, id);
  }

  Future<UserCar> createCar(Map<String, dynamic> data) async {
    final response = await _dio.post(Endpoints.garageCars, data: data);
    return _parseCarResponse(response.data, null);
  }

  Future<UserCar> updateCar(int id, Map<String, dynamic> data) async {
    final response = await _dio.patch(
      Endpoints.garageCar.replaceAll('{id}', id.toString()),
      data: data,
    );
    return _parseCarResponse(response.data, id);
  }

  Future<void> deleteCar(int id) async {
    final response = await _dio.delete(
      Endpoints.garageCar.replaceAll('{id}', id.toString()),
    );
    final body = response.data;
    if (body is Map && body['success'] == false) {
      throw Exception(_extractMessage(body, 'Не удалось удалить автомобиль.'));
    }
  }

  // ── Service Records ─────────────────────────────────────────────────────────

  Future<List<ServiceRecord>> getServiceRecords(int userCarId) async {
    final response = await _dio.get(
      Endpoints.garageServiceRecords,
      queryParameters: {'user_car_id': userCarId},
    );
    final data = response.data;
    if (data is! Map) return [];
    if (data['success'] == false) {
      throw Exception(_extractMessage(data, 'Не удалось загрузить записи.'));
    }
    final list = data['data'];
    if (list is! List) return [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ServiceRecordModel.fromJson)
        .toList();
  }

  Future<ServiceRecord> getServiceRecord(int id) async {
    final response = await _dio.get(
      Endpoints.garageServiceRecord.replaceAll('{id}', id.toString()),
    );
    return _parseRecordResponse(response.data, id);
  }

  Future<ServiceRecord> createServiceRecord(Map<String, dynamic> data) async {
    final response = await _dio.post(Endpoints.garageServiceRecords, data: data);
    final body = response.data;

    // Извлекаем ID из любого уровня вложенности до вызова общего парсера
    int? createdId;
    if (body is Map) {
      final d = body['data'];
      if (d is Map) createdId = d['id'] is int ? d['id'] as int : null;
      createdId ??= body['id'] is int ? body['id'] as int : null;
    }

    return _parseRecordResponse(body, createdId);
  }

  Future<ServiceRecord> updateServiceRecord(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch(
      Endpoints.garageServiceRecord.replaceAll('{id}', id.toString()),
      data: data,
    );
    return _parseRecordResponse(response.data, id);
  }

  Future<void> deleteServiceRecord(int id) async {
    final response = await _dio.delete(
      Endpoints.garageServiceRecord.replaceAll('{id}', id.toString()),
    );
    final body = response.data;
    if (body is Map && body['success'] == false) {
      throw Exception(_extractMessage(body, 'Не удалось удалить запись.'));
    }
  }

  // ── Media ────────────────────────────────────────────────────────────────────

  Future<Attachment> uploadMedia(
    int recordId,
    String filePath,
    String filename,
  ) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: filename),
    });
    final response = await _dio.post(
      Endpoints.garageServiceRecordMedia.replaceAll('{id}', recordId.toString()),
      data: formData,
    );
    final body = response.data;
    if (body is! Map) throw Exception('Некорректный ответ сервера.');
    if (body['success'] == false) {
      throw Exception(_extractMessage(body, 'Не удалось загрузить файл.'));
    }
    final dataJson = body['data'];
    if (dataJson is! Map<String, dynamic>) {
      throw Exception('Не удалось загрузить файл.');
    }
    return AttachmentModel.fromJson(dataJson);
  }

  Future<void> deleteMedia(int recordId, int mediaId) async {
    final response = await _dio.delete(
      Endpoints.garageServiceRecordMediaDelete
          .replaceAll('{id}', recordId.toString())
          .replaceAll('{mediaId}', mediaId.toString()),
    );
    final body = response.data;
    if (body is Map && body['success'] == false) {
      throw Exception(_extractMessage(body, 'Не удалось удалить файл.'));
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  UserCar _parseCarResponse(dynamic responseData, int? fallbackId) {
    if (responseData is! Map) throw Exception('Некорректный ответ сервера.');
    if (responseData['success'] == false) {
      throw Exception(_extractMessage(responseData, 'Ошибка при сохранении автомобиля.'));
    }
    final data = responseData['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Некорректный ответ сервера.');
    }
    return UserCarModel.fromJson(data);
  }

  ServiceRecord _parseRecordResponse(dynamic responseData, int? fallbackId) {
    if (responseData is! Map) throw Exception('Некорректный ответ сервера.');
    if (responseData['success'] == false) {
      throw Exception(_extractMessage(responseData, 'Ошибка при сохранении записи.'));
    }

    // Пробуем разные структуры ответа
    final raw = responseData['data'];
    Map<String, dynamic>? payload;
    if (raw is Map<String, dynamic>) {
      payload = raw['id'] != null ? raw : (raw['data'] is Map<String, dynamic> ? raw['data'] as Map<String, dynamic> : null);
    }

    if (payload != null) {
      return ServiceRecordModel.fromJson(payload);
    }

    // Сервер вернул успех без тела — возвращаем минимальную запись с известным ID
    if (fallbackId != null) {
      return ServiceRecordModel(
        id: fallbackId,
        userCarId: 0,
        serviceDate: '',
        serviceType: '',
        items: [],
        attachments: [],
      );
    }

    throw Exception('Некорректный ответ сервера.');
  }

  String _extractMessage(Map body, String fallback) {
    final message = body['message'];
    if (message is String && message.trim().isNotEmpty) return message.trim();
    return fallback;
  }
}
