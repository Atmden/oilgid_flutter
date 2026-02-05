import Flutter
import UIKit
import YandexMapsMobile

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let apiKey = Bundle.main.object(forInfoDictionaryKey: "YANDEX_MAPKIT_API_KEY") as? String
    YMKMapKit.setApiKey(apiKey ?? "")
    YMKMapKit.setLocale("ru_RU")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
