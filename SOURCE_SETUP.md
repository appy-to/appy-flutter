# Build the example from public sources

Registry distribution is being prepared. The current branch uses local native SDKs. Clone the native repositories beside this plugin using the directory names below; this matches `native-sdk.json` without editing it.

```bash
mkdir appy-sdks
cd appy-sdks
git clone https://github.com/appy-to/appy-ios-sdk.git ios
git clone https://github.com/appy-to/appy-android-sdk.git android
git clone https://github.com/appy-to/appy-flutter.git flutter
```

For Android, with an Android SDK and JDK installed:

```bash
cd android
./gradlew :appy-sdk:publishReleasePublicationToLocalRepository
cd ..
```

Set `ANDROID_HOME` to your Android SDK directory if Gradle cannot find it. For iOS, use macOS with Xcode installed. The native source packages retain their MIT license; dependencies retain their separate licenses.

Then follow the [example app setup](example/README.md), which covers platform link configuration, the publishable key and running the example. The example requires an Appy Enterprise app to use the hosted endpoints.

For consumer app integration and the upcoming registry installation, see the [quickstart](QUICKSTART.md) and [full guide](README.md). Do not install the current branch as though the native packages were already available from all registries.
