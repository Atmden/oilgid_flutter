import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oil_gid/core/api/app_api.dart';
import '../../data/repositories/car_mark_repository_impl.dart';
import '../../domain/entities/car_mark.dart';
import '../../domain/repositories/car_mark_repository.dart';

class CarMarkNotifier extends AsyncNotifier<List<CarMark>> {
  int _page = 1;
  bool _hasMore = true;
  String? _search;

  CarMarkRepository get repository => ref.read(carMarkRepositoryProvider);

  @override
  FutureOr<List<CarMark>> build() async {
    // загружаем первую страницу
    final items = await repository.getCarMarks(page: _page);
    _page++;
    _hasMore = items.isNotEmpty;
    return items;
  }

  Future<void> loadMore({String? search, bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _search = search;
      state = const AsyncValue.loading();
    } else {
      _search = search ?? _search;
    }

    if (!_hasMore) return;

    state = await AsyncValue.guard(() async {
      final newItems = await repository.getCarMarks(
        search: _search,
        page: _page,
      );

      _hasMore = newItems.isNotEmpty;
      _page++;

      final oldItems = state.value ?? [];
      return [...oldItems, ...newItems];
    });
  }

  Future<void> refresh({String? search}) async {
    _page = 1;
    _hasMore = true;
    _search = search;
    state = const AsyncValue.loading();
    final items = await repository.getCarMarks(search: _search, page: _page);
    _page++;
    _hasMore = items.isNotEmpty;
    state = AsyncValue.data(items);
  }
}

final carMarkRepositoryProvider = Provider<CarMarkRepository>((ref) {
  final api = AppApi().carMarkApi;
  return CarMarkRepositoryImpl(api);
});

final carMarkNotifierProvider = AsyncNotifierProvider<CarMarkNotifier, List<CarMark>>(() {
  return CarMarkNotifier();
});