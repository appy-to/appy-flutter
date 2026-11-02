package to.appy.sdk.flutter

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.ArgumentMatchers.anyString
import org.mockito.ArgumentMatchers.isNull
import org.mockito.Mockito
import to.appy.sdk.Appy
import to.appy.sdk.AppyAdNetwork
import to.appy.sdk.AppyAttribution
import to.appy.sdk.AppyDeepLink
import to.appy.sdk.AppyDeepLinkResult
import to.appy.sdk.AppyError
import to.appy.sdk.AppyLogLevel
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull

internal class AppyMappingTest {
    @Test
    fun configKeepsNativeDefaultsWhenOptionsAreMissing() {
        val config = AppyMapping.config(mapOf("publishableKey" to "appy_pk_test"))

        assertEquals("appy_pk_test", config.publishableKey)
        assertEquals(emptyList(), config.linkDomains)
        assertEquals(AppyLogLevel.ERROR, config.logLevel)
        assertEquals(false, config.openDeferredDeepLinks)
        assertEquals(5_000L, config.deferredDeepLinkTimeoutMillis)
        assertEquals(500L, config.launchLinkWaitMillis)
        assertEquals(10_000, config.requestTimeoutMillis)
        assertEquals("https://api.appy.to", config.apiBaseUrl)
        assertEquals(true, config.collectInstallReferrer)
        assertNull(config.metaAppId)
    }

    @Test
    fun configMapsEveryOptionFromDart() {
        val config = AppyMapping.config(
            mapOf(
                "publishableKey" to "appy_pk_test",
                "linkDomains" to listOf("acme.appy.to", "go.acme.com"),
                "emailLinkDomains" to listOf("links.example.com"),
                "logLevel" to "debug",
                "openDeferredDeepLinks" to true,
                "deferredDeepLinkTimeoutMillis" to 8000,
                "launchLinkWaitMillis" to 250,
                "requestTimeoutMillis" to 20000,
                "apiBaseUrl" to "https://staging-api.appy.to",
                "android" to mapOf("collectInstallReferrer" to false, "metaAppId" to "1234567890"),
            ),
        )

        assertEquals(listOf("acme.appy.to", "go.acme.com"), config.linkDomains)
        assertEquals(listOf("links.example.com"), config.emailLinkDomains)
        assertEquals(AppyLogLevel.DEBUG, config.logLevel)
        assertEquals(true, config.openDeferredDeepLinks)
        assertEquals(8_000L, config.deferredDeepLinkTimeoutMillis)
        assertEquals(250L, config.launchLinkWaitMillis)
        assertEquals(20_000, config.requestTimeoutMillis)
        assertEquals("https://staging-api.appy.to", config.apiBaseUrl)
        assertEquals(false, config.collectInstallReferrer)
        assertEquals("1234567890", config.metaAppId)
    }

    @Test
    fun configRequiresAPublishableKey() {
        assertFailsWith<IllegalArgumentException> { AppyMapping.config(mapOf("linkDomains" to listOf("acme.appy.to"))) }
    }

    @Test
    fun logLevelsMatchDartNames() {
        assertEquals(AppyLogLevel.NONE, AppyMapping.logLevel("none"))
        assertEquals(AppyLogLevel.ERROR, AppyMapping.logLevel("error"))
        assertEquals(AppyLogLevel.WARNING, AppyMapping.logLevel("warning"))
        assertEquals(AppyLogLevel.INFO, AppyMapping.logLevel("info"))
        assertEquals(AppyLogLevel.DEBUG, AppyMapping.logLevel("debug"))
        assertEquals(AppyLogLevel.ERROR, AppyMapping.logLevel(null))
    }

    @Test
    fun resultsUseTheDartStatusNames() {
        val link = AppyDeepLink(null, null, "spring", mapOf("item" to "42"), true, 1_760_000_000_000L)

        assertEquals(
            mapOf(
                "status" to "found",
                "link" to mapOf(
                    "url" to null,
                    "deeplinkUrl" to null,
                    "slug" to "spring",
                    "parameters" to mapOf("item" to "42"),
                    "isDeferred" to true,
                    "clickedAtMillis" to 1_760_000_000_000L,
                ),
            ),
            AppyMapping.result(AppyDeepLinkResult.Found(link)),
        )
        assertEquals(mapOf("status" to "notFound"), AppyMapping.result(AppyDeepLinkResult.NotFound))
        assertEquals(mapOf("status" to "failed", "error" to "timeout"), AppyMapping.result(AppyDeepLinkResult.Failed(AppyError.TIMEOUT)))
        assertEquals(mapOf("status" to "failed", "error" to "network"), AppyMapping.result(AppyDeepLinkResult.Failed(AppyError.NETWORK)))
        assertEquals(
            mapOf("status" to "failed", "error" to "invalidResponse"),
            AppyMapping.result(AppyDeepLinkResult.Failed(AppyError.INVALID_RESPONSE)),
        )
    }

    @Test
    fun attributionIncludesTheAdNetwork() {
        val attribution = AppyAttribution(
            isOrganic = false,
            linkSlug = null,
            linkTitle = null,
            source = null,
            medium = null,
            campaign = null,
            clickedAt = null,
            network = AppyAdNetwork("google_ads", "42", "Spring", "7", null, null, "gclid-1", "click"),
        )

        val mapped = AppyMapping.attribution(attribution)

        assertEquals(false, mapped["isOrganic"])
        assertEquals(
            mapOf(
                "name" to "google_ads",
                "campaignId" to "42",
                "campaignName" to "Spring",
                "adGroupId" to "7",
                "adGroupName" to null,
                "adId" to null,
                "clickId" to "gclid-1",
                "touch" to "click",
            ),
            mapped["network"],
        )
    }

    @Test
    fun propertiesKeepOnlyStringKeys() {
        assertEquals(
            mapOf("sku" to "A1", "qty" to 2),
            AppyMapping.properties(mapOf("sku" to "A1", "qty" to 2, 3 to "ignored")),
        )
        assertEquals(emptyMap(), AppyMapping.properties(null))
    }

    @Test
    fun unknownMethodsAreNotImplemented() {
        val result = Mockito.mock(MethodChannel.Result::class.java)

        AppySdkPlugin().onMethodCall(MethodCall("surprise", null), result)

        Mockito.verify(result).notImplemented()
    }

    @Test
    fun nativeSdkVersionIsReported() {
        val result = Mockito.mock(MethodChannel.Result::class.java)

        AppySdkPlugin().onMethodCall(MethodCall("getNativeSdkVersion", null), result)

        Mockito.verify(result).success(Appy.SDK_VERSION)
    }

    @Test
    fun configureBeforeTheEngineIsAttachedFails() {
        val result = Mockito.mock(MethodChannel.Result::class.java)

        AppySdkPlugin().onMethodCall(MethodCall("configure", mapOf("publishableKey" to "appy_pk_test")), result)

        Mockito.verify(result).error(Mockito.eq("invalid_argument"), anyString(), isNull())
    }
}
