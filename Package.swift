// swift-tools-version:5.3

import PackageDescription

let version = "1.5.1"
// Checksum of the file at `sdkUrl` link. To generate: `swift package compute-checksum build/talkable_ios_sdk.zip`
let checksum = "18cc1cf4dd028279b91065ddf19e1c7beae3f99ea657ba1c5a3380743c94b52b"
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
