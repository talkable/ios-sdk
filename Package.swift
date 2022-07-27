// swift-tools-version:5.3

import PackageDescription

let version = "1.4.14"
// Checksum of the file at `sdkUrl` link. To generate: `swift package compute-checksum build/talkable_ios_sdk.zip`
let checksum = "9006dbc5e48fc6bc51de881eda6aa0c60df2fe96d7b6f1bccc4e86411d38954b"
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
