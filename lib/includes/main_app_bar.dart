import 'package:flutter/material.dart';
import 'package:oil_gid/themes/default.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainAppBar({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      title: Text(title, style: appTitleStyle),
      backgroundColor: appBgColor,
      iconTheme: IconThemeData(color: mainMenuIconColor),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
