import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import '../storage/app_info.dart';

class InitTokenGenerator {
  static final String appSecret = appInfo['secret']!;

  static Future<Map<String, dynamic>> generate() async {
    final payload = {
      'platform': Platform.isAndroid ? 'android' : 'ios',
      'device_id': Platform.isAndroid
          ? (await DeviceInfoPlugin().androidInfo).id
          : (await DeviceInfoPlugin().iosInfo).identifierForVendor,
      'app_key': appInfo['app_key'],
      'version': appInfo['version'],
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'nonce': const Uuid().v4(),
    };

    final jsonPayload = jsonEncode(payload);

    final signature = Hmac(
      sha256,
      utf8.encode(appSecret),
    ).convert(utf8.encode(jsonPayload)).toString();

    return {'payload': payload, 'signature': signature};
  }
}
