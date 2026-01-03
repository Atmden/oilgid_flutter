import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/car_mark_provider.dart';
import '../../domain/entities/car_mark.dart';

class CarMarkDropdown extends ConsumerWidget {
  const CarMarkDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = ScrollController();

    scrollController.addListener(() {
      // Когда пользователь долистал до 80% списка - подгружаем еще
      if (scrollController.position.pixels >= 
          scrollController.position.maxScrollExtent * 0.8) {
        ref.read(carMarkNotifierProvider.notifier).loadMore();
      }
    });

    return DropdownSearch<CarMark>(
      items: (String? filter, infiniteScrollProps) async {
        // Обновляем список с учетом фильтра
        await ref
            .read(carMarkNotifierProvider.notifier)
            .refresh(search: filter);

        return ref.read(carMarkNotifierProvider).value ?? [];
      },
      // Как отображать объект в виде текста
      itemAsString: (CarMark mark) => mark.cyrillic_name,
      // Как сравнивать два объекта (обычно по id)
      compareFn: (CarMark a, CarMark b) => a.id == b.id,
      popupProps: PopupProps.modalBottomSheet(
        showSearchBox: true,
        listViewProps: ListViewProps(
          controller: scrollController,
        ),
      ),
      decoratorProps: const DropDownDecoratorProps(
        decoration: InputDecoration(
          labelText: 'Марка автомобиля',
        ),
      ),
      onChanged: (value) {
        // сохраняешь выбранную марку
      },
    );
  }
}
