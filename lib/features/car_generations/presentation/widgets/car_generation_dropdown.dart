import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/car_generation_provider.dart';
import '../../domain/entities/car_generation.dart';

class CarGenerationDropdown extends ConsumerWidget {
  const CarGenerationDropdown({
    super.key,
    this.value,
    this.onChanged,
    required this.markId,
    required this.modelId,
  });

  final CarGeneration? value;
  final ValueChanged<CarGeneration?>? onChanged;
  final int markId;
  final int modelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DropdownSearch<CarGeneration>(
      selectedItem: value,
      // Используем встроенную пагинацию DropdownSearch
      items: (String? filter, LoadProps? loadProps) async {
        final skip = loadProps?.skip ?? 0;
        final take = loadProps?.take ?? 25;
        final page = (skip ~/ take) + 1;
        return ref
            .read(carGenerationRepositoryProvider)
            .getCarGenerations(markId: markId, modelId: modelId, search: filter, page: page, perPage: take);
      },
      // Как отображать объект в виде текста
      itemAsString: (CarGeneration generation) => "${generation.name} (${generation.year_from} - ${generation.year_to})",
      // Как сравнивать два объекта (обычно по id)
      compareFn: (CarGeneration a, CarGeneration b) => a.id == b.id,
    
      popupProps: PopupProps.modalBottomSheet(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            border: UnderlineInputBorder(),
            hintText: 'Введите поколение для поиска',
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
          labelText: 'Поколение автомобиля',
        ),
      ),
      onChanged: onChanged,
    );
  }
}
