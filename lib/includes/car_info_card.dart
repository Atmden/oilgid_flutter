import 'package:flutter/material.dart';
import 'package:oil_gid/themes/app_colors.dart';

class CarInfoCard extends StatelessWidget {
  const CarInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_car, color: Colors.white),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Автомобиль не выбран',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/car_select');
            },
            child: const Text('Выбрать', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
