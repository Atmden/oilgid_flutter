import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/car_mark_provider.dart';
import '../../domain/entities/car_mark.dart';

class CarMarkDropdown extends ConsumerWidget {
  const CarMarkDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DropdownSearch<CarMark>(
      // Используем встроенную пагинацию DropdownSearch
      items: (String? filter, LoadProps? loadProps) async {
        final skip = loadProps?.skip ?? 0;
        final take = loadProps?.take ?? 25;
        final page = (skip ~/ take) + 1;
        return ref
            .read(carMarkRepositoryProvider)
            .getCarMarks(search: filter, page: page, perPage: take);
      },
      // Как отображать объект в виде текста
      itemAsString: (CarMark mark) => mark.name,
      // Как сравнивать два объекта (обычно по id)
      compareFn: (CarMark a, CarMark b) => a.id == b.id,
    
      popupProps: PopupProps.modalBottomSheet(
        showSearchBox: true,
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

          labelText: 'Марка автомобиля',
        ),
      ),
      onChanged: (value) {
        // сохраняешь выбранную марку
      },
    );
  }
}
