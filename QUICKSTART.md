# Flutter quickstart

**Release status:** pub.dev and the native packages are being prepared. The current source tree uses local native SDK dependencies; the command below is for the verified public release. Do not publish this plugin while `native-sdk.json` has `source: local`. For a working source checkout, follow [Build the example from public sources](SOURCE_SETUP.md). Contact Appy for current onboarding.

## 1. Prepare your app

Requires Flutter 3.44+, Dart 3.12+, iOS 13+ and Android API 21+. Register your iOS Team ID/bundle ID and Android package/signing certificates in **Apps & SDK**. The SDK endpoints require Enterprise. Copy the publishable key and link domain.

## 2. Install after public release

```bash
flutter pub add appy_sdk
```

Follow [platform setup](README.md#2-platform-setup) for Associated Domains, Android App Links, custom schemes, backup exclusions and Flutter's built-in deep-link handler. CocoaPods apps also need the native `AppySDK` Git dependency shown in [Install](README.md#install).

## 3. Configure

Before `runApp`, after `WidgetsFlutterBinding.ensureInitialized()`:

```dart
import 'package:appy_sdk/appy_sdk.dart';

await Appy.configure(const AppyConfiguration(
  publishableKey: 'appy_pk_REPLACE_WITH_YOUR_PUBLISHABLE_KEY',
  linkDomains: ['YOUR_SUBDOMAIN.appy.to'],
));
```

## 4. Receive links

Subscribe from your router or a long-lived widget; cancel the subscription on disposal:

```dart
final subscription = Appy.onDeepLink.listen((result) {
  if (result is AppyDeepLinkFound) {
    // Route using result.link.slug and result.link.parameters.
  }
});
```

Tap a link on a device with the app installed, then test a fresh install through an Appy link. Verify callbacks and the dashboard; deferred matching depends on platform and available attribution signals.

Use only publishable keys, validate route parameters, and keep debug logging off in production. See the [example app](example/README.md) and [full guide](README.md) for consent, events and attribution.
