import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oil_gid/core/api/app_api.dart';
import '../../data/repositories/car_generation_repository_impl.dart';
import '../../domain/repositories/car_generation_repository.dart';

/// Провайдер репозитория выпусков
final carGenerationRepositoryProvider = Provider<CarGenerationRepository>((ref) {
  final api = AppApi().carGenerationApi;
  return CarGenerationRepositoryImpl(api);
});