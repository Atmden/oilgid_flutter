import 'package:flutter/material.dart';
import 'package:oil_gid/features/car_marks/presentation/widgets/car_mark_dropdown.dart';
import 'package:oil_gid/themes/app_colors.dart';

class CarSelectScreen extends StatefulWidget {
  const CarSelectScreen({super.key});

  @override
  State<CarSelectScreen> createState() => _CarSelectScreenState();
}

class _CarSelectScreenState extends State<CarSelectScreen> {
  String? selectedBrand;
  String? selectedModel;
  String? selectedYear;
  String? selectedEngine;

  // Пример данных — в реальном приложении это будет API
  final List<String> brands = ['ToyotaAAA', 'BMW', 'Mercedes', 'Hyundai'];
  final Map<String, List<String>> modelsMap = {
    'Toyota': ['Camry', 'Corolla', 'RAV4'],
    'BMW': ['X5', 'X3', '3 Series'],
    'Mercedes': ['C-Class', 'E-Class', 'GLA'],
    'Hyundai': ['Elantra', 'Tucson', 'Santa Fe'],
  };
  final Map<String, List<String>> yearsMap = {
    'Camry': ['2018', '2019', '2020', '2021'],
    'Corolla': ['2017', '2018', '2019'],
    'RAV4': ['2019', '2020', '2021'],
    'X5': ['2018', '2019', '2020'],
    'X3': ['2017', '2018', '2019'],
    '3 Series': ['2018', '2019', '2020'],
    'C-Class': ['2017', '2018', '2019'],
    'E-Class': ['2018', '2019', '2020'],
    'GLA': ['2019', '2020', '2021'],
    'Elantra': ['2017', '2018', '2019'],
    'Tucson': ['2018', '2019', '2020'],
    'Santa Fe': ['2019', '2020', '2021'],
  };
  final Map<String, List<String>> enginesMap = {
    'Camry': ['2.0 бензин', '2.5 бензин'],
    'Corolla': ['1.8 бензин'],
    'RAV4': ['2.0 бензин', '2.5 бензин'],
    'X5': ['3.0 дизель', '4.0 бензин'],
    'X3': ['2.0 бензин', '3.0 дизель'],
    '3 Series': ['2.0 бензин'],
    'C-Class': ['2.0 бензин', '2.2 дизель'],
    'E-Class': ['2.0 бензин', '3.0 дизель'],
    'GLA': ['2.0 бензин'],
    'Elantra': ['1.6 бензин'],
    'Tucson': ['2.0 бензин', '2.4 бензин'],
    'Santa Fe': ['2.0 бензин', '2.2 дизель'],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Выбор автомобиля'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CarMarkDropdown(),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Марка',
              value: selectedBrand,
              items: brands,
              onChanged: (val) {
                setState(() {
                  selectedBrand = val;
                  selectedModel = null;
                  selectedYear = null;
                  selectedEngine = null;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Модель',
              value: selectedModel,
              items: selectedBrand != null
                  ? modelsMap[selectedBrand!] ?? []
                  : [],
              onChanged: (val) {
                setState(() {
                  selectedModel = val;
                  selectedYear = null;
                  selectedEngine = null;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Год',
              value: selectedYear,
              items: selectedModel != null
                  ? yearsMap[selectedModel!] ?? []
                  : [],
              onChanged: (val) {
                setState(() {
                  selectedYear = val;
                  selectedEngine = null;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Двигатель',
              value: selectedEngine,
              items: selectedModel != null
                  ? enginesMap[selectedModel!] ?? []
                  : [],
              onChanged: (val) {
                setState(() {
                  selectedEngine = val;
                });
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed:
                    (selectedBrand != null &&
                        selectedModel != null &&
                        selectedYear != null &&
                        selectedEngine != null)
                    ? _finish
                    : null,
                child: const Text(
                  'Сохранить',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  void _finish() {
    Navigator.pop(context, {
      'brand': selectedBrand,
      'model': selectedModel,
      'year': selectedYear,
      'engine': selectedEngine,
    });
  }
}
