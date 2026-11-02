# appy_sdk example

A one-screen app that configures Appy, prints every deep link and attribution result, tracks a purchase, builds a share link and toggles tracking.

The platform folders are not checked in. Generate them once with your Flutter version, then add the link configuration.

This is Appy’s included **demo app**, not your production app. Copy your own key and link domain from **Apps & SDK → your app → SDK setup**. The demo’s Bundle ID and Android application ID must match an app you registered for testing. [Which values do I replace?](../SETUP.md)

## 1. Native SDKs

With the repositories arranged as in [source setup](../SOURCE_SETUP.md), `../native-sdk.json` has `"source": "local"`, so the plugin builds against the neighboring `ios/` checkout and the neighboring `android/` checkout. Publish the Android SDK to its local Maven folder first:

```bash
cd ../../android && ./gradlew :appy-sdk:publishReleasePublicationToLocalRepository
```

iOS needs nothing: Swift Package Manager reads the neighboring `ios/` checkout directly. With CocoaPods instead of Swift Package Manager, add `pod 'AppySDK', :path => '../../../ios'` inside `target 'Runner' do` in `ios/Podfile`.

## 2. Generate the platform folders

```bash
flutter create --platforms=android,ios --org to.appy.example .
```

## 3. Android

In `android/app/src/main/AndroidManifest.xml`, inside the `MainActivity` `<activity>` element, add the App Link and custom-scheme filters and turn off Flutter's own deep linking so Appy links are routed only once:

```xml
<meta-data android:name="flutter_deeplinking_enabled" android:value="false" />

<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="acme.appy.to" />
</intent-filter>

<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="acme" />
</intent-filter>
```

## 4. iOS

In Xcode (`open ios/Runner.xcworkspace`), select the Runner target:

1. **Signing & Capabilities > + Capability > Associated Domains**, add `applinks:acme.appy.to`.
2. **Info > URL Types**, add the scheme `acme`.
3. In `ios/Runner/Info.plist`, add `FlutterDeepLinkingEnabled` with the Boolean value `NO`.

## 5. Run

```bash
flutter run --dart-define=APPY_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY --dart-define=APPY_LINK_DOMAIN=acme.appy.to
```

Open a link while the app runs and again after stopping it:

```bash
xcrun simctl openurl booted "https://acme.appy.to/spring?item=42"
adb shell 'am start -W -a android.intent.action.VIEW -c android.intent.category.BROWSABLE -d "https://acme.appy.to/spring?item=42"'
```

A Universal Link needs a signed build with the Associated Domains entitlement and an AASA file listing your Team ID and bundle ID; see the plugin README.
