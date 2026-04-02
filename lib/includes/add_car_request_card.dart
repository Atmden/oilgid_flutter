import 'package:flutter/material.dart';
import 'package:oil_gid/core/storage/token_storage.dart';
import 'package:oil_gid/themes/app_colors.dart';

class AddCarRequestCard extends StatelessWidget {
  const AddCarRequestCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Не нашли свой автомобиль?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Оставьте заявку и мы его добавим',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.primarySoft,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () async {
                final token = await TokenStorage().getUserToken();
                if (token == null) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Вы не авторизованы'),
                      content: Text(
                        'Для того чтобы оставить заявку, вам необходимо авторизоваться',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/login');
                          },
                          child: Text('Ок'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color.fromARGB(255, 120, 129, 209),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                          child: Text('Отмена'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color.fromARGB(255, 209, 126, 120),
                          ),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                Navigator.pushNamed(context, '/add_car_request').then((value) {
                  if (value == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Заявка успешно отправлена'),
                      ),
                    );
                  }
                });
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Оставить заявку',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
