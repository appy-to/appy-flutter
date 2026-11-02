import AppySDK
import Flutter
import UIKit

public final class AppySdkPlugin: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate {
    private static var isConfigured = false

    private let deepLinks = AppyStreamHandler(
        start: { sink in Appy.shared.onDeepLink = { sink(AppyMapping.result($0)) } },
        stop: { Appy.shared.onDeepLink = nil }
    )
    private let attributions = AppyStreamHandler(
        start: { sink in Appy.shared.onAttribution = { sink(AppyMapping.attribution($0)) } },
        stop: { Appy.shared.onAttribution = nil }
    )

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = AppySdkPlugin()
        let methods = FlutterMethodChannel(name: "to.appy.sdk/methods", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: methods)
        FlutterEventChannel(name: "to.appy.sdk/deep_links", binaryMessenger: registrar.messenger())
            .setStreamHandler(instance.deepLinks)
        FlutterEventChannel(name: "to.appy.sdk/attribution", binaryMessenger: registrar.messenger())
            .setStreamHandler(instance.attributions)
        registrar.addApplicationDelegate(instance)
        registrar.addSceneDelegate(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "configure":
            guard let configuration = AppyMapping.configuration(arguments) else {
                result(FlutterError(code: "invalid_argument", message: "publishableKey is required", details: nil))
                return
            }
            if !Self.isConfigured {
                Self.isConfigured = true
                Appy.configure(configuration)
            }
            result(nil)
        case "handleUrl":
            guard let url = (arguments["url"] as? String).flatMap(URL.init(string:)) else {
                result(false)
                return
            }
            result(Appy.shared.handle(url: url))
        case "track":
            Appy.shared.track(
                arguments["name"] as? String ?? "",
                properties: arguments["properties"] as? [String: Any] ?? [:],
                revenue: AppyMapping.revenue(arguments["revenue"]),
                currency: arguments["currency"] as? String,
                deduplicationId: arguments["deduplicationId"] as? String
            )
            result(nil)
        case "setUserId":
            Appy.shared.setUserId(arguments["userId"] as? String)
            result(nil)
        case "setTrackingEnabled":
            Appy.shared.isTrackingEnabled = arguments["enabled"] as? Bool ?? true
            result(nil)
        case "isTrackingEnabled":
            result(Appy.shared.isTrackingEnabled)
        case "buildLink":
            let slug = arguments["slug"] as? String ?? ""
            let parameters = arguments["parameters"] as? [String: String] ?? [:]
            result(Appy.shared.link(slug: slug, parameters: parameters)?.absoluteString)
        case "flush":
            Appy.shared.flush()
            result(nil)
        case "getAttribution":
            result(Appy.shared.attribution.map(AppyMapping.attribution))
        case "getLatestDeepLink":
            result(Appy.shared.latestDeepLink.map(AppyMapping.link))
        case "getNativeSdkVersion":
            result(Appy.sdkVersion)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func application(
        _ application: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        Self.usesScenes ? false : receive(url)
    }

    public func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([Any]) -> Void
    ) -> Bool {
        Self.usesScenes ? false : receive(userActivity)
    }

    public func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions?
    ) -> Bool {
        guard let connectionOptions else {
            return false
        }
        let activities = connectionOptions.userActivities.map(receive)
        let urls = connectionOptions.urlContexts.map { receive($0.url) }
        return (activities + urls).contains(true)
    }

    public func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
        URLContexts.map { receive($0.url) }.contains(true)
    }

    public func scene(_ scene: UIScene, continue userActivity: NSUserActivity) -> Bool {
        receive(userActivity)
    }

    private func receive(_ userActivity: NSUserActivity) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL else {
            return false
        }
        return receive(url)
    }

    private func receive(_ url: URL) -> Bool {
        let isAppyLink = Appy.shared.handle(url: url)
        return Self.isConfigured ? isAppyLink : Self.hasClickId(url)
    }

    static func hasClickId(_ url: URL) -> Bool {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .contains { $0.name.lowercased() == "appy_click_id" } ?? false
    }

    private static var usesScenes: Bool {
        Bundle.main.object(forInfoDictionaryKey: "UIApplicationSceneManifest") != nil
    }
}

final class AppyStreamHandler: NSObject, FlutterStreamHandler {
    private let start: (@escaping FlutterEventSink) -> Void
    private let stop: () -> Void

    init(start: @escaping (@escaping FlutterEventSink) -> Void, stop: @escaping () -> Void) {
        self.start = start
        self.stop = stop
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        start(events)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        stop()
        return nil
    }
}
