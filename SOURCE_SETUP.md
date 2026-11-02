# Build the example from public sources

For routine app integration, use the registry installation in [Quickstart](QUICKSTART.md). To develop the plugin together with its native libraries, clone all three repositories. Keep the directory names shown below so the example can find them. Start by [getting your app's dashboard values](SETUP.md).

```bash
mkdir appy-sdks
cd appy-sdks
git clone https://github.com/appy-to/appy-ios-sdk.git ios
git clone https://github.com/appy-to/appy-android-sdk.git android
git clone https://github.com/appy-to/appy-flutter.git flutter
```

Before building against neighboring native checkouts, set `"source": "local"` in `flutter/native-sdk.json`. Published packages use `"source": "published"`; do not publish your local development configuration.

For Android, with an Android SDK and JDK installed:

```bash
cd android
./gradlew :appy-sdk:publishReleasePublicationToLocalRepository
cd ..
```

Set `ANDROID_HOME` to your Android SDK directory if Gradle cannot find it. For iOS, use macOS with Xcode installed. The native source packages retain their MIT license; dependencies retain their separate licenses.

Then follow the [example app setup](example/README.md), which covers platform link configuration, the publishable key and running the example. The example requires an Appy Enterprise app to use the hosted endpoints.

For consumer app integration, use the [quickstart](QUICKSTART.md) and [full guide](README.md).
