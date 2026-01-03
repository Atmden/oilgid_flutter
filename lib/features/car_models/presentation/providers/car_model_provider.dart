import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oil_gid/core/api/app_api.dart';
import '../../data/repositories/car_model_repository_impl.dart';
import '../../domain/repositories/car_model_repository.dart';

/// Провайдер репозитория моделей
final carModelRepositoryProvider = Provider<CarModelRepository>((ref) {
  final api = AppApi().carModelApi;
  return CarModelRepositoryImpl(api);
});