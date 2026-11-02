package to.appy.sdk.flutter

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import to.appy.sdk.Appy

class AppySdkPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware,
    PluginRegistry.NewIntentListener {

    private var applicationContext: Context? = null
    private var methodChannel: MethodChannel? = null
    private var deepLinkChannel: EventChannel? = null
    private var attributionChannel: EventChannel? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var ownsDeepLinkListener = false
    private var ownsAttributionListener = false

    private val launchIntentState = object : ActivityPluginBinding.OnSaveInstanceStateListener {
        override fun onSaveInstanceState(bundle: Bundle) {
            bundle.putBoolean(RESTORED_KEY, true)
        }

        override fun onRestoreInstanceState(bundle: Bundle?) {
            if (bundle?.getBoolean(RESTORED_KEY) != true) {
                activityBinding?.activity?.intent?.let(Appy::handleIntent)
            }
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL).also { it.setMethodCallHandler(this) }
        deepLinkChannel = EventChannel(binding.binaryMessenger, DEEP_LINK_CHANNEL).also {
            it.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    ownsDeepLinkListener = true
                    Appy.setDeepLinkListener { result -> events.success(AppyMapping.result(result)) }
                }

                override fun onCancel(arguments: Any?) {
                    releaseDeepLinkListener()
                }
            })
        }
        attributionChannel = EventChannel(binding.binaryMessenger, ATTRIBUTION_CHANNEL).also {
            it.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    ownsAttributionListener = true
                    Appy.setAttributionListener { attribution -> events.success(AppyMapping.attribution(attribution)) }
                }

                override fun onCancel(arguments: Any?) {
                    releaseAttributionListener()
                }
            })
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        deepLinkChannel?.setStreamHandler(null)
        attributionChannel?.setStreamHandler(null)
        releaseDeepLinkListener()
        releaseAttributionListener()
        methodChannel = null
        deepLinkChannel = null
        attributionChannel = null
        applicationContext = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        attach(binding)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        attach(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detach()
    }

    override fun onDetachedFromActivity() {
        detach()
    }

    override fun onNewIntent(intent: Intent): Boolean = Appy.handleIntent(intent)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "configure" -> {
                    configure(call.arguments as? Map<*, *> ?: emptyMap<String, Any?>())
                    result.success(null)
                }
                "handleUrl" -> result.success(Appy.handleUri(Uri.parse(call.argument<String>("url").orEmpty())))
                "track" -> {
                    Appy.track(
                        call.argument<String>("name").orEmpty(),
                        AppyMapping.properties(call.argument<Any>("properties")),
                        call.argument<Number>("revenue")?.toDouble(),
                        call.argument<String>("currency"),
                        call.argument<String>("deduplicationId"),
                    )
                    result.success(null)
                }
                "setUserId" -> {
                    Appy.setUserId(call.argument<String>("userId"))
                    result.success(null)
                }
                "setTrackingEnabled" -> {
                    Appy.isTrackingEnabled = call.argument<Boolean>("enabled") ?: true
                    result.success(null)
                }
                "isTrackingEnabled" -> result.success(Appy.isTrackingEnabled)
                "buildLink" -> {
                    val parameters = (call.argument<Map<String, String>>("parameters")).orEmpty()
                    result.success(Appy.buildLink(call.argument<String>("slug").orEmpty(), parameters)?.toString())
                }
                "flush" -> {
                    Appy.flush()
                    result.success(null)
                }
                "getAttribution" -> result.success(Appy.attribution?.let(AppyMapping::attribution))
                "getLatestDeepLink" -> result.success(Appy.latestDeepLink?.let(AppyMapping::link))
                "getNativeSdkVersion" -> result.success(Appy.SDK_VERSION)
                else -> result.notImplemented()
            }
        } catch (e: IllegalArgumentException) {
            result.error("invalid_argument", e.message, null)
        }
    }

    private fun configure(arguments: Map<*, *>) {
        val context = applicationContext ?: throw IllegalArgumentException("The plugin is not attached to an engine")
        val config = AppyMapping.config(arguments)
        synchronized(AppySdkPlugin::class.java) {
            if (!configured) {
                Appy.init(context, config)
                configured = true
            }
        }
    }

    private fun attach(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addOnNewIntentListener(this)
        binding.addOnSaveStateListener(launchIntentState)
    }

    private fun detach() {
        activityBinding?.removeOnNewIntentListener(this)
        activityBinding?.removeOnSaveStateListener(launchIntentState)
        activityBinding = null
    }

    private fun releaseDeepLinkListener() {
        if (ownsDeepLinkListener) {
            Appy.setDeepLinkListener(null)
            ownsDeepLinkListener = false
        }
    }

    private fun releaseAttributionListener() {
        if (ownsAttributionListener) {
            Appy.setAttributionListener(null)
            ownsAttributionListener = false
        }
    }

    internal companion object {
        const val METHOD_CHANNEL = "to.appy.sdk/methods"
        const val DEEP_LINK_CHANNEL = "to.appy.sdk/deep_links"
        const val ATTRIBUTION_CHANNEL = "to.appy.sdk/attribution"
        const val RESTORED_KEY = "to.appy.sdk.flutter.restored"

        @Volatile
        var configured = false
    }
}
