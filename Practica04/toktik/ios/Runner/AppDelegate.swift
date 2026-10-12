import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var iconChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(name: "toktik/app_icon",
      binaryMessenger: engineBridge.applicationRegistrar.messenger())
    iconChannel = channel
    channel.setMethodCallHandler { call, result in
      guard call.method == "setIcon" else { result(FlutterMethodNotImplemented); return }
      guard let icon = call.arguments as? String,
        ["normal", "halloween", "christmas", "valentines"].contains(icon) else {
        result(FlutterError(code: "INVALID_ICON", message: "Icono desconocido", details: nil)); return
      }
      DispatchQueue.main.async {
        let app = UIApplication.shared
        guard app.supportsAlternateIcons else {
          result(FlutterError(code: "UNSUPPORTED", message: "Iconos alternativos no disponibles", details: nil)); return
        }
        let alternateNames = ["halloween": "Halloween", "christmas": "Christmas", "valentines": "Valentines"]
        let name = alternateNames[icon]
        guard app.alternateIconName != name else { result(nil); return }
        app.setAlternateIconName(name) { error in
          if let error = error {
            result(FlutterError(code: "ICON_UPDATE_FAILED", message: error.localizedDescription, details: nil))
          } else { result(nil) }
        }
      }
    }
  }
}
