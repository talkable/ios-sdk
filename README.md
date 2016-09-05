# talkable-ios-sdk
Talkable Integration and API for iOS devices.

## Hacking

* Install dependencies: ```bundle install```
* Deploy SDK to AWS S3: ```rake deploy```
* Increment or modify version in ```Info.plist``` file and in ```TKBLConstants.m``` file
* Make a release, when version is incremented: ```rake release```


## TODO
- [ ] Direct SMS Sharing
- [ ] CocoaPod
- [X] Safari View Controller
- [ ] Special Mobile Tracking method
  - [X] Altenative Cookie
  - [ ] Explicitly specified visitor id
- [ ] Pair Device's idfa and Visitor UUID
- [X] Fraud detection
- [X] Network Queue and Offline
- [ ] Update AFNetworking
- [ ] WKWebView
- [ ] Unify origin URL parameter key to use only one name aka purchase, affiliate_member, event => origin
- [ ] Native contact importer
- [X] Rename app_installed to ios-app-installed
- [X] Introduce full_name in contact importer
- [ ] Investigate the size of SDK binary
