import Foundation
import SwiftUI
import Capacitor
import ZendeskCoreSDK
import SupportSDK
import SupportProvidersSDK
import CommonUISDK
import MessagingSDK

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitor.ionicframework.com/docs/plugins/ios
 */
@objc(ZendeskChat)
public class ZendeskChat: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "ZendeskChat"
    public let jsName = "ZendeskChat"

    private var sdkInitialized = false
    private var liveChatEnabled: Bool = true
    private var primaryColor: Color = Color(red: 0, green: 0.43, blue: 0.145)

    // Persisted across cold starts so setIdentity is never called again for the
    // same anonymous user — re-calling it generates a new token and breaks
    // existing ticket session access (comments return 404).
    private var identityEmail: String? {
        get { UserDefaults.standard.string(forKey: "zdkIdentityEmail") }
        set { UserDefaults.standard.set(newValue, forKey: "zdkIdentityEmail") }
    }
    private var identityName: String? {
        get { UserDefaults.standard.string(forKey: "zdkIdentityName") }
        set { UserDefaults.standard.set(newValue, forKey: "zdkIdentityName") }
    }

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
        CAPPluginMethod(name: "getUnreadCount", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isLiveChatEnabled", returnType: CAPPluginReturnPromise)
    ]

    @objc func initialize(_ call: CAPPluginCall) {
        guard let appId = call.getString("appId"),
              let clientId = call.getString("clientId"),
              let zendeskUrl = call.getString("zendeskUrl") else {
            call.reject("Missing appId, clientId or zendeskUrl")
            return
        }

        DispatchQueue.main.async {
            // Only initialize the SDK once per app session; re-initializing resets
            // the anonymous identity and breaks access to existing tickets.
            if !self.sdkInitialized {
                ZendeskCoreSDK.Zendesk.initialize(appId: appId, clientId: clientId, zendeskUrl: zendeskUrl)
                SupportSDK.Support.initialize(withZendesk: ZendeskCoreSDK.Zendesk.instance)
                self.sdkInitialized = true
            }

            self.liveChatEnabled = call.getBool("enableLiveChat") ?? true

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
           let uiColor = UIColor(hex: primaryColorHex) {
            CommonUISDK.CommonTheme.currentTheme.primaryColor = uiColor
            primaryColor = Color(uiColor)
        }
    }

    @objc func setVisitorInfo(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            let name = call.getString("name") ?? ""
            let email = call.getString("email") ?? ""

            // createAnonymous produces a new auth token on every call.
            // Re-calling setIdentity invalidates the current session, causing
            // the ticket detail view to fail with "Failed to load comments"
            // while the list still shows from cache. Skip if identity unchanged.
            guard email != self.identityEmail else {
                call.resolve()
                return
            }

            let identity = ZendeskCoreSDK.Identity.createAnonymous(name: name, email: email)
            ZendeskCoreSDK.Zendesk.instance?.setIdentity(identity)
            self.identityEmail = email
            self.identityName = name
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
            var color = self.primaryColor
            if let hex = call.getString("primaryColor"),
               let uiColor = UIColor(hex: hex) {
                color = Color(uiColor)
            }
            var hostingVC: UIViewController?
            let view = TicketListView(primaryColor: color, onDismiss: {
                hostingVC?.dismiss(animated: true)
            })
            let vc = UIHostingController(rootView: view)
            hostingVC = vc
            vc.modalPresentationStyle = .fullScreen
            self.bridge?.viewController?.present(vc, animated: true)
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

        // The Classic Support SDK identifies its push notifications by the
        // presence of "zendesk_sdk_request_id" in the payload (docs: handle_push_notifications_wh).
        let isZendesk = data["zendesk_sdk_request_id"] != nil
        call.resolve(["isZendeskNotification": isZendesk, "wasHandled": false])
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

    @objc func isLiveChatEnabled(_ call: CAPPluginCall) {
        call.resolve(["enabled": liveChatEnabled])
    }

    @objc func registerPushToken(_ call: CAPPluginCall) {
        guard let tokenString = call.getString("token") else {
            call.reject("Missing token")
            return
        }
        DispatchQueue.main.async {
            // Docs require stripping spaces, "<" and ">" before registering
            // (handle_push_notifications_wh).
            let cleanedToken = tokenString
                .replacingOccurrences(of: "<", with: "")
                .replacingOccurrences(of: ">", with: "")
                .replacingOccurrences(of: " ", with: "")
            if let zendesk = ZendeskCoreSDK.Zendesk.instance {
                ZendeskCoreSDK.ZDKPushProvider(zendesk: zendesk).register(deviceIdentifier: cleanedToken, locale: Locale.current.identifier) { _, _ in }
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
