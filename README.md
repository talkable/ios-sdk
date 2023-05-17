# Talkable iOS SDK

[![Version](https://img.shields.io/cocoapods/v/TalkableSDK.svg?style=flat-square)](http://cocoapods.org/pods/TalkableSDK)
[![License](https://img.shields.io/cocoapods/l/TalkableSDK.svg?style=flat-square)](http://cocoapods.org/pods/TalkableSDK)
[![Platform](https://img.shields.io/cocoapods/p/TalkableSDK.svg?style=flat-square)](http://cocoapods.org/pods/TalkableSDK)

Talkable SDK makes it easy to integrate Talkable referral functionality into iOS apps.

## Requirements
- [x] iOS 9 or higher.

## Installation

Talkable supports multiple methods for installing the SDK in a project.

### Swift Package Manager

Add Talkable SDK as a dependency to [`Package.swift`](https://www.swift.org/package-manager/) under `dependencies`:

```swift
dependencies: [
    .package(url: "https://github.com/talkable/ios-sdk.git", .upToNextMajor(from: "1.5.1"))
]
```

### CocoaPods

To integrate Talkable SDK into your Xcode project using CocoaPods, specify it in your [`Podfile`](https://guides.cocoapods.org/using/the-podfile.html):

```ruby
pod 'TalkableSDK', '~> 1.5.1'
```

## Manual building

To build the SDK manually, run the following command:

```bash
$ rake archive
```

## Documentation

<https://docs.talkable.com/ios_sdk>
