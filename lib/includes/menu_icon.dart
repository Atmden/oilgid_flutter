import 'package:flutter/material.dart';
import 'package:flutter_slider_drawer/flutter_slider_drawer.dart';
import 'package:oil_gid/includes/slider_menu.dart';
import 'package:oil_gid/includes/user_icon.dart';

class MenuIcon extends StatefulWidget {
  const MenuIcon({super.key});

  @override
  State<MenuIcon> createState() => _MenuIconState();
}

class _MenuIconState extends State<MenuIcon> {
  final GlobalKey<SliderDrawerState> _sliderDrawerKey =
      GlobalKey<SliderDrawerState>();

  late String title = '123';
  @override
  void initState() {
    title = "Home";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SliderDrawer(
        appBar: SliderAppBar(config: SliderAppBarConfig(title: Text(title))),
        sliderOpenSize: 179,
        slider: SliderMenu(
          onItemClick: (title) {
            _sliderDrawerKey.currentState?.closeSlider();
            setState(() {
              this.title = title;
            });
          },
        ),
        child: UserIcon(),
      ),
    );
  }
}
