import Flutter
import UIKit

public class TraccarFlutterPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {
    private let traccarController = TraccarController.shared
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "traccar_flutter", binaryMessenger: registrar.messenger())
        let instance = TraccarFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        NotificationCenter.default.addObserver(
            instance,
            selector: #selector(applicationWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == "STOP_SERVICE" {
            traccarController.stopService()
        }
        completionHandler()
    }
    
    @objc func applicationWillTerminate() {
        traccarController.terminate()
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "init":
            traccarController.setup()
            result("initialized successfully")
            break
        case "setConfigs" :
            guard let args = call.arguments as? [String: Any] else { return }
            traccarController.setConfigs(
                deviceId: args["deviceId"] as? String,
                serverUrl: args["serverUrl"] as? String,
                interval: args["interval"] as? Int,
                distance: args["distance"] as? Int,
                angle: args["angle"] as? Int,
                accuracyLevel: AccuracyLevel(rawValue: args["accuracy"] as! String),
                offlineBuffering: args["offlineBuffering"] as? Bool
            )
            result("configs set")
            break
            
        case "startService" :
            traccarController.startService()
            result("service started")
            break
            
        case "stopService" :
            traccarController.stopService()
            result("service stopped")
            break
            
        case "statusActivity" :
            if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
                let newViewController = StatusViewController()
                newViewController.modalPresentationStyle = .formSheet
                rootViewController.present(newViewController, animated: true, completion: nil)
                result("launch status activity")
            }
            break
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
