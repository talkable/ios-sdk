// swift-tools-version:5.0

import PackageDescription

let version = "1.4.12"
// Checksum of the file at `sdkUrl` link. To generate: `swift package compute-checksum build/talkable_ios_sdk.zip`
let checksum = "a71ababfedb1fa485258a4928ed00891f08cff2c06b77ccddd28f538e192b580"
let sdkUrl = "https://github.com/talkable/ios-sdk/releases/download/\(version)/talkable_ios_sdk_\(version).zip"

let package = Package(
    name: "TalkableSDK",
    platforms: [.iOS(.v9)],
    products: [
        .library(
            name: "TalkableSDK",
            targets: ["TalkableSDK"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "TalkableSDK",
            url: sdkUrl,
            checksum: checksum
        )
    ]
)
