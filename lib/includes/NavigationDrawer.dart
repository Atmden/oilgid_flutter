import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:oil_gid/lang/ru.dart';
import 'package:oil_gid/model/NavigationItem.dart';
import 'package:oil_gid/pages/about.dart';
import 'package:oil_gid/pages/blog.dart';
import 'package:oil_gid/pages/home_page.dart';
import 'package:oil_gid/themes/default.dart';

class Navigationdrawer extends StatelessWidget {
  const Navigationdrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Material(
        color: mainMenuBgColor,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 50, 24, 0),
          child: Column(
            children: [
              headerWidget(context, false),
              const SizedBox(height: 1),
              const Divider(thickness: 1, height: 10, color: Colors.grey),
              const SizedBox(height: 20),
              Navigationitem(
                title: 'Главная',
                icon: Icons.home_max,
                onPressed: () => onItemPressed(context, index: '0'),
              ),
              Navigationitem(
                title: 'Блог',
                icon: Icons.home,
                onPressed: () => onItemPressed(context, index: '1'),
              ),
              Navigationitem(
                title: 'Личные заметки',
                icon: Icons.home,
                onPressed: () => onItemPressed(context, index: '2'),
              ),
              Navigationitem(
                title: 'Профиль',
                icon: Icons.home,
                onPressed: () => onItemPressed(context, index: '3'),
              ),
              Navigationitem(
                title: 'Настройки',
                icon: Icons.home,
                onPressed: () => onItemPressed(context, index: '4'),
              ),
              Navigationitem(
                title: 'Еще что-то',
                icon: Icons.home,
                onPressed: () => onItemPressed(context, index: '5'),
              ),
              Navigationitem(
                title: 'И еще',
                icon: Icons.home,
                onPressed: () => onItemPressed(context, index: '6'),
              ),
              Navigationitem(
                title: AboutUsText,
                icon: FontAwesomeIcons.circleQuestion,
                onPressed: () => onItemPressed(context, index: 'about'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onItemPressed(BuildContext context, {required String index}) {
    Navigator.pop(context);

    switch (index) {
      case '0':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
      case '1':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Blog()),
        );
        break;
      case 'about':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const About()),
        );
        break;
    }
  }

  Widget headerWidget(BuildContext context, bool isLoggedIn) {
    if (isLoggedIn) {
      return headerUser();
    } else {
      return headerGuest(context);
    }
  }

  Widget headerGuest(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.popAndPushNamed(context, '/login');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage('assets/icon/icon.png'),
            ),
            const SizedBox(width: 20),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  // Text(
                  //   'Гость',
                  //   style: TextStyle(fontSize: 14, color: Colors.white),
                  // ),
                  // SizedBox(height: 8),
                  Text(
                    'Войдите, чтобы получить доступ ко всем функциям',
                    style: TextStyle(fontSize: 10, color: Colors.white70),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const Icon(Icons.login, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }

  Widget headerUser() {
    const url = 'https://picsum.photos/200';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: url,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
            ),
          ),
          SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Denis',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
              SizedBox(height: 10),
              Text(
                '+77057505444',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
