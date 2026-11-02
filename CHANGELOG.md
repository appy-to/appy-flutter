# Changelog

All notable changes to `appy_sdk` are documented in this file. The plugin follows [Semantic Versioning](https://semver.org).

## 1.0.0 - Unreleased

First release, built on the Appy iOS SDK 1.0 and the Appy Android SDK 1.0.

### Added

- `Appy.configure` with `AppyConfiguration`: publishable key, link domains, log level, `openDeferredDeepLinks`, deferred deep link timeout, launch link wait, request timeout, API base URL, and `AppyAndroidOptions` with `collectInstallReferrer` and `metaAppId`. A second call in the same process, for example after a hot restart, is ignored.
- `AppyConfiguration.emailLinkDomains`, passed to the native SDKs, for email click-tracking domains that open the app.
- `Appy.onDeepLink`, a broadcast stream of the sealed `AppyDeepLinkResult`: `AppyDeepLinkFound`, `AppyDeepLinkNotFound` and `AppyDeepLinkFailed` with `AppyError`. The first launch after install emits exactly once; every Appy link that opens the app, cold or warm, emits `AppyDeepLinkFound`. A result that arrives while nothing listens is delivered once to the next listener.
- `Appy.onAttribution` and `Appy.getAttribution()` with `AppyAttribution` and `AppyAdNetwork` (organic or attributed, link, UTM source, medium and campaign, click time, Google Ads or Meta network data).
- `Appy.getLatestDeepLink()`, `Appy.handleUrl()` for links from notifications and QR scanners, and `Appy.buildLink()` for share links.
- `Appy.track()` with properties, revenue, currency and `deduplicationId`; `Appy.flush()`.
- `Appy.setUserId()`, `Appy.setTrackingEnabled()` and `Appy.isTrackingEnabled()`.
- `Appy.nativeSdkVersion()` and `Appy.pluginVersion`.
- iOS: links from the app delegate and from the scene delegate (`FlutterSceneLifeCycleDelegate`), so apps work before and after the UIScene migration. Swift Package Manager and CocoaPods support.
- Android: the launch intent is handled once per activity creation and not again after a configuration change or process restore; links that arrive while the app runs are forwarded from `onNewIntent`. Built-in Kotlin, compatible with Android Gradle Plugin 9.
- Minimum versions: Flutter 3.44, Dart 3.12, iOS 13, Android 5.0 (API 21).
