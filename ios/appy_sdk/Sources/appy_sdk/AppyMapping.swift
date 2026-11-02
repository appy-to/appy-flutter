import AppySDK
import Foundation

enum AppyMapping {
    static func configuration(_ arguments: [String: Any]) -> AppyConfiguration? {
        guard let publishableKey = arguments["publishableKey"] as? String else {
            return nil
        }
        var configuration = AppyConfiguration(
            publishableKey: publishableKey,
            linkDomains: arguments["linkDomains"] as? [String] ?? []
        )
        configuration.emailLinkDomains = arguments["emailLinkDomains"] as? [String] ?? []
        configuration.logLevel = logLevel(arguments["logLevel"] as? String)
        configuration.openDeferredDeepLinks = arguments["openDeferredDeepLinks"] as? Bool ?? false
        if let millis = (arguments["deferredDeepLinkTimeoutMillis"] as? NSNumber)?.doubleValue {
            configuration.deferredDeepLinkTimeout = millis / 1000
        }
        if let millis = (arguments["launchLinkWaitMillis"] as? NSNumber)?.doubleValue {
            configuration.launchLinkWaitInterval = millis / 1000
        }
        if let millis = (arguments["requestTimeoutMillis"] as? NSNumber)?.doubleValue {
            configuration.requestTimeout = millis / 1000
        }
        if let apiBaseURL = (arguments["apiBaseUrl"] as? String).flatMap(URL.init(string:)) {
            configuration.apiBaseURL = apiBaseURL
        }
        return configuration
    }

    static func logLevel(_ name: String?) -> AppyLogLevel {
        switch name {
        case "none": return .none
        case "warning": return .warning
        case "info": return .info
        case "debug": return .debug
        default: return .error
        }
    }

    static func result(_ result: AppyDeepLinkResult) -> [String: Any] {
        switch result {
        case .found(let link):
            return ["status": "found", "link": self.link(link)]
        case .notFound:
            return ["status": "notFound"]
        case .failed(let error):
            return ["status": "failed", "error": self.error(error)]
        }
    }

    static func error(_ error: AppyError) -> String {
        switch error {
        case .timeout: return "timeout"
        case .network: return "network"
        case .invalidResponse: return "invalidResponse"
        }
    }

    static func link(_ link: AppyDeepLink) -> [String: Any] {
        [
            "url": link.url?.absoluteString as Any,
            "deeplinkUrl": link.deeplinkURL?.absoluteString as Any,
            "slug": link.slug,
            "parameters": link.parameters,
            "isDeferred": link.isDeferred,
            "clickedAtMillis": millis(link.clickedAt) as Any,
        ]
    }

    static func attribution(_ attribution: AppyAttribution) -> [String: Any] {
        [
            "isOrganic": attribution.isOrganic,
            "linkSlug": attribution.linkSlug as Any,
            "linkTitle": attribution.linkTitle as Any,
            "source": attribution.source as Any,
            "medium": attribution.medium as Any,
            "campaign": attribution.campaign as Any,
            "clickedAtMillis": millis(attribution.clickedAt) as Any,
            "network": attribution.network.map(network) as Any,
        ]
    }

    static func revenue(_ value: Any?) -> Decimal? {
        guard let number = value as? NSNumber else {
            return nil
        }
        return Decimal(string: "\(number.doubleValue)")
    }

    private static func network(_ network: AppyAdNetwork) -> [String: Any] {
        [
            "name": network.name,
            "campaignId": network.campaignId as Any,
            "campaignName": network.campaignName as Any,
            "adGroupId": network.adGroupId as Any,
            "adGroupName": network.adGroupName as Any,
            "adId": network.adId as Any,
            "clickId": network.clickId as Any,
            "touch": network.touch as Any,
        ]
    }

    private static func millis(_ date: Date?) -> Int64? {
        date.map { Int64(($0.timeIntervalSince1970 * 1000).rounded()) }
    }
}
