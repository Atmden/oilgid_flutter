import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:oil_gid/includes/NavigationDrawer.dart';
import 'package:oil_gid/includes/main_app_bar.dart';
import 'package:oil_gid/lang/ru.dart';
import 'package:url_launcher/url_launcher.dart';

class About extends StatefulWidget {
  const About({super.key});

  @override
  State<About> createState() => _AboutState();
}

class _AboutState extends State<About> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Navigationdrawer(),
      appBar: MainAppBar(title: AboutUsText),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Логотип
              Image.asset('assets/icon/icon.png', width: 150),
              const SizedBox(height: 24),

              // Информационный текст
              Text(
                aboutText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 32),

              // Кнопки отдельно с отступами
              SizedBox(
                width: double.infinity, // кнопка растянется по ширине
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/privacy_policy');
                  },
                  icon: const Icon(Icons.privacy_tip),
                  label: const Text(PrivacyPolicyText),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 0,
                    ),
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/terms_of_use');
                  },
                  icon: const Icon(Icons.description),
                  label: const Text(TermsOfUseText),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Кнопки соцсетей
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(FontAwesomeIcons.instagram),
                    iconSize: 32,
                    onPressed: openInstagram,
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(FontAwesomeIcons.telegram),
                    iconSize: 32,
                    onPressed: openTelegram,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Footer
              const Text(
                'Спасибо за использование OIL ГИД!',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                '© ${DateTime.now().year} Все права защищены.',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> openInstagram() async {
  final Uri uri = Uri.parse('instagram://user?username=your_username');
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    // fallback на веб, если Instagram не установлен
    final Uri webUri = Uri.parse('https://instagram.com/your_username');
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }
}

Future<void> openTelegram() async {
  const String username = 'your_username'; // например, @oil_gid
  final Uri appUri = Uri.parse('tg://resolve?domain=$username');
  final Uri webUri = Uri.parse('https://t.me/$username');

  // Сначала пытаемся открыть в приложении
  if (!await launchUrl(appUri, mode: LaunchMode.externalApplication)) {
    // Если приложение не установлено, fallback на веб
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }
}
