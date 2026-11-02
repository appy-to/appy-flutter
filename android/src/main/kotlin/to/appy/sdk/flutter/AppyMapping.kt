package to.appy.sdk.flutter

import to.appy.sdk.AppyAdNetwork
import to.appy.sdk.AppyAttribution
import to.appy.sdk.AppyConfig
import to.appy.sdk.AppyDeepLink
import to.appy.sdk.AppyDeepLinkResult
import to.appy.sdk.AppyError
import to.appy.sdk.AppyLogLevel

internal object AppyMapping {
    fun config(arguments: Map<*, *>): AppyConfig {
        val publishableKey = arguments["publishableKey"] as? String
            ?: throw IllegalArgumentException("publishableKey is required")
        val linkDomains = (arguments["linkDomains"] as? List<*>).orEmpty().filterIsInstance<String>()
        val android = arguments["android"] as? Map<*, *>
        return AppyConfig(publishableKey, linkDomains).apply {
            emailLinkDomains = (arguments["emailLinkDomains"] as? List<*>).orEmpty().filterIsInstance<String>()
            logLevel = logLevel(arguments["logLevel"] as? String)
            openDeferredDeepLinks = arguments["openDeferredDeepLinks"] as? Boolean ?: false
            (arguments["deferredDeepLinkTimeoutMillis"] as? Number)?.let { deferredDeepLinkTimeoutMillis = it.toLong() }
            (arguments["launchLinkWaitMillis"] as? Number)?.let { launchLinkWaitMillis = it.toLong() }
            (arguments["requestTimeoutMillis"] as? Number)?.let { requestTimeoutMillis = it.toInt() }
            (arguments["apiBaseUrl"] as? String)?.let { apiBaseUrl = it }
            (android?.get("collectInstallReferrer") as? Boolean)?.let { collectInstallReferrer = it }
            metaAppId = android?.get("metaAppId") as? String
        }
    }

    fun logLevel(name: String?): AppyLogLevel = when (name) {
        "none" -> AppyLogLevel.NONE
        "warning" -> AppyLogLevel.WARNING
        "info" -> AppyLogLevel.INFO
        "debug" -> AppyLogLevel.DEBUG
        else -> AppyLogLevel.ERROR
    }

    fun result(result: AppyDeepLinkResult): Map<String, Any?> = when (result) {
        is AppyDeepLinkResult.Found -> mapOf("status" to "found", "link" to link(result.link))
        AppyDeepLinkResult.NotFound -> mapOf("status" to "notFound")
        is AppyDeepLinkResult.Failed -> mapOf("status" to "failed", "error" to error(result.error))
    }

    fun error(error: AppyError): String = when (error) {
        AppyError.TIMEOUT -> "timeout"
        AppyError.NETWORK -> "network"
        AppyError.INVALID_RESPONSE -> "invalidResponse"
    }

    fun link(link: AppyDeepLink): Map<String, Any?> = mapOf(
        "url" to link.url?.toString(),
        "deeplinkUrl" to link.deeplinkUri?.toString(),
        "slug" to link.slug,
        "parameters" to link.parameters,
        "isDeferred" to link.isDeferred,
        "clickedAtMillis" to link.clickedAt,
    )

    fun attribution(attribution: AppyAttribution): Map<String, Any?> = mapOf(
        "isOrganic" to attribution.isOrganic,
        "linkSlug" to attribution.linkSlug,
        "linkTitle" to attribution.linkTitle,
        "source" to attribution.source,
        "medium" to attribution.medium,
        "campaign" to attribution.campaign,
        "clickedAtMillis" to attribution.clickedAt,
        "network" to attribution.network?.let(::network),
    )

    private fun network(network: AppyAdNetwork): Map<String, Any?> = mapOf(
        "name" to network.name,
        "campaignId" to network.campaignId,
        "campaignName" to network.campaignName,
        "adGroupId" to network.adGroupId,
        "adGroupName" to network.adGroupName,
        "adId" to network.adId,
        "clickId" to network.clickId,
        "touch" to network.touch,
    )

    fun properties(raw: Any?): Map<String, Any?> =
        (raw as? Map<*, *>).orEmpty().entries
            .filter { it.key is String }
            .associate { it.key as String to it.value }
}
