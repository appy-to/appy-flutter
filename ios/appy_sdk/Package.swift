// swift-tools-version: 5.9

import Foundation
import PackageDescription

struct NativeSDK {
    let dependency: Package.Dependency
    let packageName: String
}

func nativeSDK() -> NativeSDK {
    let pluginRoot = URL(fileURLWithPath: Context.packageDirectory)
        .resolvingSymlinksInPath()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    let manifest = pluginRoot.appendingPathComponent("native-sdk.json")
    let json = (try? Data(contentsOf: manifest)).flatMap { try? JSONSerialization.jsonObject(with: $0) } as? [String: Any] ?? [:]
    let ios = json["ios"] as? [String: Any] ?? [:]
    let version = json["version"] as? String ?? "1.0.0"
    let packageURL = ios["packageUrl"] as? String ?? "https://github.com/appy-to/appy-ios-sdk.git"

    if json["source"] as? String == "local", let localPath = ios["localPath"] as? String {
        let directory = pluginRoot.appendingPathComponent(localPath).standardizedFileURL
        return NativeSDK(dependency: .package(path: directory.path), packageName: directory.lastPathComponent)
    }
    let repository = URL(string: packageURL)?.deletingPathExtension().lastPathComponent ?? "appy-ios-sdk"
    return NativeSDK(dependency: .package(url: packageURL, from: Version(stringLiteral: version)), packageName: repository)
}

let native = nativeSDK()

let package = Package(
    name: "appy_sdk",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "appy-sdk", targets: ["appy_sdk"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        native.dependency
    ],
    targets: [
        .target(
            name: "appy_sdk",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "AppySDK", package: native.packageName)
            ]
        )
    ]
)
