// swift-tools-version:5.3

import PackageDescription

let version = "1.5.1"
// Checksum of the file at `sdkUrl` link. To generate: `swift package compute-checksum build/talkable_ios_sdk.zip`
let checksum = "d893d6ea4b651deb119db6f463ed1bf4ffc4dc7d7cf6b1c0566c14d25f6e4ca6"
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
