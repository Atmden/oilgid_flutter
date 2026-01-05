import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/car_configuration_provider.dart';
import '../../domain/entities/car_configuration.dart';

class CarConfigurationDropdown extends ConsumerWidget {
  const CarConfigurationDropdown({
    super.key,
    this.value,
    this.onChanged,
    required this.markId,
    required this.modelId,
    required this.generationId,
  });

  final CarConfiguration? value;
  final ValueChanged<CarConfiguration?>? onChanged;
  final int markId;
  final int modelId;
  final int generationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DropdownSearch<CarConfiguration>(
      selectedItem: value,
      // Используем встроенную пагинацию DropdownSearch
      items: (String? filter, LoadProps? loadProps) async {
        final skip = loadProps?.skip ?? 0;
        final take = loadProps?.take ?? 25;
        final page = (skip ~/ take) + 1;
        return ref
            .read(carConfigurationRepositoryProvider)
            .getCarConfigurations(
              markId: markId,
              modelId: modelId,
              generationId: generationId,
              search: filter,
              page: page,
              perPage: take,
            );
      },
      // Как отображать объект в виде текста
      itemAsString: (CarConfiguration configuration) => configuration.name,
      // Как сравнивать два объекта (обычно по id)
      compareFn: (CarConfiguration a, CarConfiguration b) => a.id == b.id,

      popupProps: PopupProps.modalBottomSheet(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            border: UnderlineInputBorder(),
            hintText: 'Введите конфигурацию для поиска',
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
        decoration: InputDecoration(labelText: 'Конфигурация автомобиля'),
      ),
      onChanged: onChanged,
    );
  }
}
