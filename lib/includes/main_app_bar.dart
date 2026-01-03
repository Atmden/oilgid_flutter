import 'package:flutter/material.dart';
import 'package:oil_gid/themes/default.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainAppBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      title: Text(title, style: appTitleStyle),
      backgroundColor: appBgColor,
      iconTheme: IconThemeData(color: mainMenuIconColor),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
