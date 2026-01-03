import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/car_model_provider.dart';
import '../../domain/entities/car_model.dart';

class CarModelDropdown extends ConsumerWidget {
  const CarModelDropdown({
    super.key,
    this.value,
    this.onChanged,
    required this.markId,
  });

  final CarModel? value;
  final ValueChanged<CarModel?>? onChanged;
  final int markId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DropdownSearch<CarModel>(
      selectedItem: value,
      // Используем встроенную пагинацию DropdownSearch
      items: (String? filter, LoadProps? loadProps) async {
        final skip = loadProps?.skip ?? 0;
        final take = loadProps?.take ?? 25;
        final page = (skip ~/ take) + 1;
        return ref
            .read(carModelRepositoryProvider)
            .getCarModels(markId: markId, search: filter, page: page, perPage: take);
      },
      // Как отображать объект в виде текста
      itemAsString: (CarModel model) => "${model.name} (${model.year_from} - ${model.year_to})",
      // Как сравнивать два объекта (обычно по id)
      compareFn: (CarModel a, CarModel b) => a.id == b.id,
    
      popupProps: PopupProps.modalBottomSheet(
        showSearchBox: true,
        modalBottomSheetProps: const ModalBottomSheetProps(
          isScrollControlled: true,
          backgroundColor: Colors.white,
        ),
        containerBuilder: (context, child) {
          final bottom = MediaQuery.of(context).padding.bottom;
          print(bottom);
          return SafeArea(
              child: child,
          );
        },
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            border: UnderlineInputBorder(),
            hintText: 'Введите марку для поиска',
            hintStyle: TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(Icons.search),
            prefixIconColor: Colors.grey,
            prefixIconConstraints: BoxConstraints(minWidth: 40),
          ),
        ),
        // Включаем встроенный infinite scroll + серверный поиск
        disableFilter: true,
        infiniteScrollProps: const InfiniteScrollProps(
          loadProps: LoadProps(take: 25),
        ),
      ),
      decoratorProps: const DropDownDecoratorProps(
        decoration: InputDecoration(
          labelText: 'Модель автомобиля',
        ),
      ),
      onChanged: onChanged,
    );
  }
}
