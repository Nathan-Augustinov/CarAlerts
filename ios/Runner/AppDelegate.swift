import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NotificationPermissionBridge")!
    let channel = FlutterMethodChannel(name: "car_alerts/notification_permissions", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      let center = UNUserNotificationCenter.current()
      func reportStatus() {
        center.getNotificationSettings { settings in
          let status: String
          switch settings.authorizationStatus {
          case .notDetermined: status = "notRequested"
          case .authorized, .provisional, .ephemeral: status = "enabled"
          default: status = "disabled"
          }
          DispatchQueue.main.async { result(status) }
        }
      }
      switch call.method {
      case "timezone": result(TimeZone.current.identifier)
      case "loadReminderIds": result(UserDefaults.standard.string(forKey: "reminder_ids") ?? "{}")
      case "saveReminderIds":
        UserDefaults.standard.set(call.arguments as? String, forKey: "reminder_ids")
        result(nil)
      case "loadReminderHistory": result(UserDefaults.standard.string(forKey: "reminder_history") ?? "{}")
      case "saveReminderHistory":
        UserDefaults.standard.set(call.arguments as? String, forKey: "reminder_history")
        result(nil)
      case "status": reportStatus()
      case "request":
        center.requestAuthorization(options: [.alert, .badge, .sound]) { _, error in
          if let error = error {
            DispatchQueue.main.async { result(FlutterError(code: "permission_request", message: error.localizedDescription, details: nil)) }
          } else { reportStatus() }
        }
      case "openSettings":
        let address: String
        if #available(iOS 16.0, *) {
          address = UIApplication.openNotificationSettingsURLString
        } else {
          address = UIApplication.openSettingsURLString
        }
        UIApplication.shared.open(URL(string: address)!) { opened in
          if opened { result(nil) }
          else { result(FlutterError(code: "settings_unavailable", message: "Could not open Settings", details: nil)) }
        }
      default: result(FlutterMethodNotImplemented)
      }
    }
  }
}
