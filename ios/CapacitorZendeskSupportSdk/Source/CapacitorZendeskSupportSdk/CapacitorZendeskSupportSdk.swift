import Foundation
import Capacitor
import ZendeskCoreSDK
import SupportSDK
import CommonUISDK
import ChatSDK
import MessagingSDK

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitor.ionicframework.com/docs/plugins/ios
 */
@objc(ZendeskChat)
public class ZendeskChat: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "ZendeskChat"
    public let jsName = "ZendeskChat"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "initialize", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setVisitorInfo", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setTheme", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setLocale", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "open", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openHelpCenter", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openTicketList", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "createTicket", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "registerPushToken", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "handleNotification", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getUnreadCount", returnType: CAPPluginReturnPromise)
    ]

    @objc func initialize(_ call: CAPPluginCall) {
        guard let appId = call.getString("appId"),
              let clientId = call.getString("clientId"),
              let zendeskUrl = call.getString("zendeskUrl") else {
            call.reject("Missing appId, clientId or zendeskUrl")
            return
        }

        DispatchQueue.main.async {
            ZendeskCoreSDK.Zendesk.initialize(appId: appId, clientId: clientId, zendeskUrl: zendeskUrl)
            SupportSDK.Support.initialize(withZendesk: ZendeskCoreSDK.Zendesk.instance)
            
            if let theme = call.getObject("theme") {
                self.applyTheme(theme)
            }

            if let locale = call.getString("locale") {
                SupportSDK.Support.instance?.helpCenterLocaleOverride = locale
            }
            
            call.resolve()
        }
    }

    @objc func setTheme(_ call: CAPPluginCall) {
        let theme = call.options as? [String: Any] ?? [:]
        DispatchQueue.main.async {
            self.applyTheme(theme)
            call.resolve()
        }
    }

    @objc func setLocale(_ call: CAPPluginCall) {
        guard let locale = call.getString("locale") else {
            call.reject("Missing locale")
            return
        }

        DispatchQueue.main.async {
            SupportSDK.Support.instance?.helpCenterLocaleOverride = locale
            call.resolve()
        }
    }

    private func applyTheme(_ theme: [String: Any]) {
        if let primaryColorHex = theme["primaryColor"] as? String,
           let color = UIColor(hex: primaryColorHex) {
            CommonUISDK.CommonTheme.currentTheme.primaryColor = color
        }
    }

    @objc func setVisitorInfo(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            let name = call.getString("name") ?? ""
            let email = call.getString("email") ?? ""

            // Identity for Support SDK
            let identity = ZendeskCoreSDK.Identity.createAnonymous(name: name, email: email)
            ZendeskCoreSDK.Zendesk.instance?.setIdentity(identity)
            
            call.resolve()
        }
    }

    @objc func open(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            do {
                let supportEngine = try SupportSDK.SupportEngine.engine()
                let viewController = try MessagingSDK.Messaging.instance.buildUI(engines: [supportEngine], configs: [])
                let navigationController = UINavigationController(rootViewController: viewController)
                self.bridge?.viewController?.present(navigationController, animated: true, completion: nil)
                call.resolve()
            } catch {
                call.reject("Could not create messaging UI")
            }
        }
    }

    @objc func openHelpCenter(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            let helpCenterUiConfig = SupportSDK.HelpCenterUiConfiguration()
            let viewController = SupportSDK.HelpCenterUi.buildHelpCenterOverviewUi(withConfigs: [helpCenterUiConfig])
            let navigationController = UINavigationController(rootViewController: viewController)
            self.bridge?.viewController?.present(navigationController, animated: true, completion: nil)
            call.resolve()
        }
    }

    @objc func openTicketList(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            let viewController = SupportSDK.RequestUi.buildRequestList(with: [])
            let navigationController = UINavigationController(rootViewController: viewController)
            self.bridge?.viewController?.present(navigationController, animated: true, completion: nil)
            call.resolve()
        }
    }

    @objc func createTicket(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            let viewController = SupportSDK.RequestUi.buildRequestUi(with: [])
            let navigationController = UINavigationController(rootViewController: viewController)
            self.bridge?.viewController?.present(navigationController, animated: true, completion: nil)
            call.resolve()
        }
    }

    @objc func handleNotification(_ call: CAPPluginCall) {
        guard let data = call.getObject("data") else {
            call.reject("Missing data")
            return
        }

        let userInfo = data as [AnyHashable: Any]

        if let zendesk = ZendeskCoreSDK.Zendesk.instance {
            // SDK is initialised — let it identify and handle the notification.
            let pushProvider = ZendeskCoreSDK.ZDKPushProvider(zendesk: zendesk)
            let isZendesk = ZendeskCoreSDK.ZDKPushProvider.isZendeskPushNotification(userInfo)
            if isZendesk {
                DispatchQueue.main.async {
                    pushProvider.handlePush(userInfo: userInfo, completion: { _ in })
                }
            }
            call.resolve(["isZendeskNotification": isZendesk, "wasHandled": isZendesk])
        } else {
            // SDK not yet initialised (cold start). Detect by payload key only so
            // the caller can navigate to the Support page where init will happen.
            let isZendesk = (data["source"] as? String) == "zendesk"
            call.resolve(["isZendeskNotification": isZendesk, "wasHandled": false])
        }
    }

    @objc func getUnreadCount(_ call: CAPPluginCall) {
        guard let zendesk = ZendeskCoreSDK.Zendesk.instance else {
            call.resolve(["count": 0])
            return
        }
        let requestProvider = SupportSDK.ZDKRequestProvider()
        requestProvider.getUpdatesForDevice { updates in
            call.resolve(["count": updates?.totalUpdates ?? 0])
        }
    }

    @objc func registerPushToken(_ call: CAPPluginCall) {
        guard let tokenString = call.getString("token") else {
            call.reject("Missing token")
            return
        }
        DispatchQueue.main.async {
            // Convert hex string (from @capacitor/push-notifications) to Data
            var data = Data()
            var hex = tokenString
            while hex.count >= 2 {
                let byteString = String(hex.prefix(2))
                hex = String(hex.dropFirst(2))
                if let byte = UInt8(byteString, radix: 16) {
                    data.append(byte)
                }
            }
            if let zendesk = ZendeskCoreSDK.Zendesk.instance {
                ZendeskCoreSDK.ZDKPushProvider(zendesk: zendesk).register(deviceToken: data, locale: Locale.current.identifier) { _, _ in }
            }
            call.resolve()
        }
    }
}

extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        if length == 6 {
            self.init(
                red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat(rgb & 0x0000FF) / 255.0,
                alpha: 1.0
            )
        } else if length == 8 {
            self.init(
                red: CGFloat((rgb & 0xFF000000) >> 24) / 255.0,
                green: CGFloat((rgb & 0x00FF0000) >> 16) / 255.0,
                blue: CGFloat((rgb & 0x0000FF00) >> 8) / 255.0,
                alpha: CGFloat(rgb & 0x000000FF) / 255.0
            )
        } else {
            return nil
        }
    }
}
