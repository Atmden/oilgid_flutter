import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oil_gid/core/api/app_api.dart';
import '../../data/repositories/car_configuration_repository_impl.dart';
import '../../domain/repositories/car_configuration_repository.dart';

/// Провайдер репозитория конфигураций
final carConfigurationRepositoryProvider = Provider<CarConfigurationRepository>(
  (ref) {
    final api = AppApi().carConfigurationApi;
    return CarConfigurationRepositoryImpl(api);
  },
);
