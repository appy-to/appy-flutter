# Add Appy to a Flutter app

Install `appy_sdk` from pub.dev, then connect it to your app as shown below.

Requires Flutter 3.44+, Dart 3.12+, iOS 13+ or Android API 21+.

## 1. Get the two values for your app

In the [Appy dashboard](https://appy.to), open **Apps & SDK → New app**, register your own app, and open its **SDK setup** card. Copy **Publishable key** and **Link domain**. If it is already registered, open that app instead of creating another one.

[Which dashboard fields do I fill in?](SETUP.md#1-add-your-app-in-the-dashboard)

In every snippet below:

- Replace `YOUR_PUBLISHABLE_KEY` with the **entire key** copied from the dashboard.
- Replace `your-app.appy.to` with the **Link domain** copied from the dashboard.
- Keep names such as `Appy`, `AppySDK` and the package imports. They name the library you are adding; your own app keeps its name and identifiers.

The hosted SDK features require an Enterprise plan. You do not need a secret API key or a `curl` registration request for these steps.

## 2. Install the package

```bash
flutter pub add appy_sdk
```

The iOS dependency supports Swift Package Manager (SPM); Android resolves the native SDK from Maven Central.

## 3. Configure the SDK in your app

After installing the package, add this import:

```dart
import 'package:appy_sdk/appy_sdk.dart';
```

In your existing `main()`, after `WidgetsFlutterBinding.ensureInitialized()` and before `runApp(...)`, configure the SDK:

```dart
await Appy.configure(const AppyConfiguration(
  publishableKey: 'YOUR_PUBLISHABLE_KEY',
  linkDomains: ['your-app.appy.to'],
));
```

Keep `appy_sdk`, `Appy` and `AppyConfiguration`: they are library names. [Set up the iOS and Android link settings](README.md#2-platform-setup) using your own dashboard app identifiers and domain.

## 4. Choose which screen to open

Subscribe from a long-lived widget or your router, and cancel the subscription when it is disposed:

```dart
final subscription = Appy.onDeepLink.listen((result) {
  if (result is AppyDeepLinkFound) {
    // Use result.link.slug and result.link.parameters in your app's navigation.
  }
});
```

## 5. Test a real link

Create a link for the dashboard app whose key and domain you copied, install the matching example or your own app, and tap the link. Check the callback before trying a fresh-install test.

The [full guide](README.md) covers events, consent and attribution. The [replacement table](SETUP.md#2-know-which-values-to-replace) explains every example name.
