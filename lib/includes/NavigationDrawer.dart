import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:oil_gid/core/storage/token_storage.dart';
import 'package:oil_gid/lang/ru.dart';
import 'package:oil_gid/model/NavigationItem.dart';
import 'package:oil_gid/pages/about.dart';
import 'package:oil_gid/pages/blog.dart';
import 'package:oil_gid/pages/home_page.dart';
import 'package:oil_gid/themes/default.dart';

class Navigationdrawer extends StatefulWidget {
  const Navigationdrawer({super.key});

  @override
  State<Navigationdrawer> createState() => _NavigationdrawerState();
}

class _NavigationdrawerState extends State<Navigationdrawer> {
  late final Future<_DrawerHeaderData> _headerDataFuture;

  @override
  void initState() {
    super.initState();
    _headerDataFuture = _loadHeaderData();
  }

  Future<_DrawerHeaderData> _loadHeaderData() async {
    final token = await TokenStorage().getUserToken();
    if (token == null || token.trim().isEmpty) {
      return const _DrawerHeaderData(isLoggedIn: false, userName: '');
    }
    final profile = await TokenStorage().getUserProfile();
    final name = (profile?['name'] ?? '').toString().trim();
    return _DrawerHeaderData(
      isLoggedIn: true,
      userName: name.isEmpty ? 'Пользователь' : name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Material(
        color: mainMenuBgColor,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 50, 24, 0),
          child: Column(
            children: [
              FutureBuilder<_DrawerHeaderData>(
                future: _headerDataFuture,
                builder: (context, snapshot) {
                  final headerData = snapshot.data;
                  if (headerData == null) {
                    return headerGuest(context);
                  }
                  return headerWidget(
                    context,
                    headerData.isLoggedIn,
                    userName: headerData.userName,
                  );
                },
              ),
              const SizedBox(height: 1),
              const Divider(thickness: 1, height: 10, color: Colors.grey),
              const SizedBox(height: 20),
              Navigationitem(
                title: 'Главная',
                icon: Icons.home_max,
                onPressed: () => onItemPressed(context, index: 'home'),
              ),
              Navigationitem(
                title: 'Профиль',
                icon: Icons.home,
                onPressed: () => onItemPressed(context, index: 'profile'),
              ),
              Navigationitem(
                title: 'Каталог масел',
                icon: Icons.oil_barrel,
                onPressed: () => onItemPressed(context, index: 'oil_catalog'),
              ),

              Navigationitem(
                title: 'Каталог магазинов',
                icon: Icons.storefront,
                onPressed: () => onItemPressed(context, index: 'shops_catalog'),
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

  Future<void> onItemPressed(
    BuildContext context, {
    required String index,
  }) async {
    Navigator.pop(context);

    switch (index) {
      case 'home':
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        break;
      case 'profile':
        final token = await TokenStorage().getUserToken();
        if (token != null && token.trim().isNotEmpty) {
          Navigator.pushNamed(context, '/profile');
        } else {
          Navigator.pushNamed(context, '/login');
        }
        break;
      case 'shops_catalog':
        Navigator.pushNamed(context, '/shops_catalog');
        break;
      case 'oil_catalog':
        Navigator.pushNamed(context, '/oil_catalog');
        break;
      case 'about':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const About()),
        );
        break;
    }
  }

  Widget headerWidget(
    BuildContext context,
    bool isLoggedIn, {
    String? userName,
  }) {
    if (isLoggedIn) {
      return headerUser(context, userName: userName ?? 'Пользователь');
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

  Widget headerUser(BuildContext context, {required String userName}) {
    const url = 'https://picsum.photos/200';
    return InkWell(
      onTap: () {
        Navigator.popAndPushNamed(context, '/profile');
      },
      child: Padding(
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
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Перейти в профиль',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeaderData {
  final bool isLoggedIn;
  final String userName;

  const _DrawerHeaderData({required this.isLoggedIn, required this.userName});
}
