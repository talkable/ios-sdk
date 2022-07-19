// swift-tools-version:5.3

import PackageDescription

let version = "1.4.13"
// Checksum of the file at `sdkUrl` link. To generate: `swift package compute-checksum build/talkable_ios_sdk.zip`
let checksum = "eefa95b7a7b7c2ca12bdf837d958d0537f054541990dcdb79867259671c63495"
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
