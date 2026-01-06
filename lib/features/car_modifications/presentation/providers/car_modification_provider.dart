import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oil_gid/core/api/app_api.dart';
import '../../data/repositories/car_modification_repository_impl.dart';
import '../../domain/repositories/car_modification_repository.dart';

/// Провайдер репозитория модификаций
final carModificationRepositoryProvider = Provider<CarModificationRepository>(
  (ref) {
    final api = AppApi().carModificationApi;
    return CarModificationRepositoryImpl(api);
  },
);
