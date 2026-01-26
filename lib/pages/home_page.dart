import 'package:flutter/material.dart';
import 'package:oil_gid/includes/NavigationDrawer.dart';
import 'package:oil_gid/includes/car_info_card.dart';
import 'package:oil_gid/includes/main_app_bar.dart';
import 'package:oil_gid/includes/quick_actions.dart';
import 'package:oil_gid/includes/select_oil_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Navigationdrawer(),
      appBar: MainAppBar(title: 'OIL ГИД'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: const [
              CarInfoCard(),
              SizedBox(height: 16),
              SelectOilCard(),
              SizedBox(height: 16),
              QuickActions(),
            ],
          ),
        ),
      ),
    );
  }
}
