import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:oil_gid/core/api/app_api.dart';
import 'package:oil_gid/includes/main_app_bar.dart';
import 'package:oil_gid/lang/ru.dart';
import 'package:oil_gid/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TermOfUse extends StatefulWidget {
  const TermOfUse({super.key, this.showAcceptButton = true});

  final bool showAcceptButton;

  @override
  State<TermOfUse> createState() => _TermOfUseState();
}

class _TermOfUseState extends State<TermOfUse> {
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
      appBar: MainAppBar(title: TermsOfServiceText),
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

                    return Scrollbar(
                      child: MarkdownWidget(
                        data: snapshot.data ?? '',
                        shrinkWrap: true,
                        config: MarkdownConfig(
                          configs: [
                            const PreConfig(),
                            const PConfig(
                              textStyle: TextStyle(fontSize: 14.0, height: 1.5),
                            ),
                            const H1Config(
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const H2Config(
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Visibility(
                visible: widget.showAcceptButton,
                child: Column(
                  children: [
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
            ],
          ),
        ),
      ),
    );
  }
}
