import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/car_modification_provider.dart';
import '../../domain/entities/car_modification.dart';

class CarModificationDropdown extends ConsumerWidget {
  const CarModificationDropdown({
    super.key,
    this.value,
    this.onChanged,
    required this.markId,
    required this.modelId,
    required this.generationId,
    required this.configurationId,
  });

  final CarModification? value;
  final ValueChanged<CarModification?>? onChanged;
  final int markId;
  final int modelId;
  final int generationId;
  final int configurationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DropdownSearch<CarModification>(
      selectedItem: value,
      // Используем встроенную пагинацию DropdownSearch
      items: (String? filter, LoadProps? loadProps) async {
        final skip = loadProps?.skip ?? 0;
        final take = loadProps?.take ?? 25;
        final page = (skip ~/ take) + 1;
        return ref
            .read(carModificationRepositoryProvider)
            .getCarModifications(
              markId: markId,
              modelId: modelId,
              generationId: generationId,
              configurationId: configurationId,
              search: filter,
              page: page,
              perPage: take,
            );
      },
      // Как отображать объект в виде текста
      itemAsString: (CarModification modification) => modification.name,
      // Как сравнивать два объекта (обычно по id)
      compareFn: (CarModification a, CarModification b) => a.id == b.id,

      popupProps: PopupProps.modalBottomSheet(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            border: UnderlineInputBorder(),
            hintText: 'Введите модификацию для поиска',
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
        decoration: InputDecoration(labelText: 'Модификация автомобиля'),
      ),
      onChanged: onChanged,
    );
  }
}
