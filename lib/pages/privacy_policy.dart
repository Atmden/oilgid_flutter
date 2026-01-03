import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:oil_gid/core/api/app_api.dart';
import 'package:oil_gid/includes/main_app_bar.dart';
import 'package:oil_gid/lang/ru.dart';
import 'package:oil_gid/pages/home_page.dart';
import 'package:oil_gid/themes/default.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyPolicy extends StatefulWidget {
  const PrivacyPolicy({super.key});

  @override
  State<PrivacyPolicy> createState() => _PrivacyPolicyState();
}

class _PrivacyPolicyState extends State<PrivacyPolicy> {
  bool _accepted = false;
  late Future<String> privacyFuture;

  Future<void> _acceptPolicy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('privacy_accepted', true);

    // Перейти в основной экран
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
  }

  @override
  void initState() {
    super.initState();
    privacyFuture = AppApi().getPrivacyPolicy();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(title: PrivacyPolicyText),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: FutureBuilder<String>(
                  future: privacyFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Не удалось загрузить документ'),
                      );
                    }

                    return MarkdownWidget(data: snapshot.data ?? '');
                  },
                ),
              ),
              CheckboxListTile(
                value: _accepted,
                onChanged: (v) => setState(() => _accepted = v ?? false),
                title: const Text(AcceptTermsText),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _accepted ? _acceptPolicy : null,
                child: const Text('Продолжить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
