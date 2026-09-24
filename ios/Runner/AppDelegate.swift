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
    let appearanceRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "AppearanceBridge")!
    let appearanceChannel = FlutterMethodChannel(name: "car_alerts/appearance", binaryMessenger: appearanceRegistrar.messenger())
    appearanceChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "load":
        result(UserDefaults.standard.string(forKey: "appearance.theme_mode") ?? "system")
      case "save":
        guard let mode = call.arguments as? String,
              ["system", "light", "dark"].contains(mode) else {
          result(FlutterError(code: "invalid_theme", message: "Unknown appearance", details: nil))
          return
        }
        UserDefaults.standard.set(mode, forKey: "appearance.theme_mode")
        result(nil)
      default: result(FlutterMethodNotImplemented)
      }
    }

    let feedbackRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "FeedbackBridge")!
    let feedbackChannel = FlutterMethodChannel(name: "car_alerts/feedback", binaryMessenger: feedbackRegistrar.messenger())
    feedbackChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "deviceDetails":
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineSize = MemoryLayout.size(ofValue: systemInfo.machine)
        let model = withUnsafePointer(to: &systemInfo.machine) { pointer in
          pointer.withMemoryRebound(to: CChar.self, capacity: machineSize) {
            String(cString: $0)
          }
        }
        let info = Bundle.main.infoDictionary ?? [:]
        let version = info["CFBundleShortVersionString"] as? String ?? "Unavailable"
        let build = info["CFBundleVersion"] as? String ?? "Unavailable"
        result([
          "model": "\(UIDevice.current.model) (\(model))",
          "os": "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)",
          "version": "\(version) (\(build))"
        ])
      case "compose":
        guard let args = call.arguments as? [String: String],
              let address = args["uri"], let url = URL(string: address), url.scheme == "mailto" else {
          result(FlutterError(code: "invalid_email", message: "Invalid email address", details: nil))
          return
        }
        UIApplication.shared.open(url, options: [:]) { opened in
          if opened { result(nil) }
          else { result(FlutterError(code: "email_unavailable", message: "No email app is available", details: nil)) }
        }
      default: result(FlutterMethodNotImplemented)
      }
    }
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
