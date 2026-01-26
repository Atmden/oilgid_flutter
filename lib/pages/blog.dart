import 'package:flutter/material.dart';
import 'package:oil_gid/includes/NavigationDrawer.dart';
import 'package:oil_gid/includes/main_app_bar.dart';

class Blog extends StatefulWidget {
  const Blog({super.key});

  @override
  State<Blog> createState() => _BlogState();
}

class _BlogState extends State<Blog> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Navigationdrawer(),
      appBar: MainAppBar(title: 'Блог'),
      body: Center(child: Text('BLOGG!')),
    );
  }
}
