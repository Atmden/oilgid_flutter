import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class UserIcon extends StatefulWidget {
  const UserIcon({super.key});

  @override
  State<UserIcon> createState() => _UserIconState();
}

class _UserIconState extends State<UserIcon> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: IconButton(onPressed: () => {}, icon: Icon(FontAwesomeIcons.user)),
    );
  }
}
