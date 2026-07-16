import UserNotifications
import FirebaseMessaging

class NotificationService: UNNotificationServiceExtension {

  var contentHandler: ((UNNotificationContent) -> Void)?
  var bestAttemptContent: UNMutableNotificationContent?

  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    self.contentHandler = contentHandler
    bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

    guard let bestAttemptContent = bestAttemptContent else {
      contentHandler(request.content)
      return
    }

    // Скачивает картинку по URL из payload (notification.image) и прикрепляет
    // её к содержимому уведомления перед показом.
    FIRMessagingExtensionHelper.populateNotificationContent(
      bestAttemptContent,
      withContentHandler: contentHandler
    )
  }

  override func serviceExtensionTimeWillExpire() {
    // Вызывается системой перед истечением таймаута (~30 сек) — показываем
    // то, что успели собрать, без картинки, если она не скачалась вовремя.
    if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
      contentHandler(bestAttemptContent)
    }
  }
}
