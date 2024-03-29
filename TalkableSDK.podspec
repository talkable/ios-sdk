Pod::Spec.new do |spec|
  spec.name         = "TalkableSDK"
  spec.version      = "1.5.1"
  spec.summary      = "Talkable SDK makes it easy to integrate Talkable referral functionality into your apps."

  spec.description  = <<-DESC
    Once integrated you can use the following Talkable capabilities:

    - Display Advocate Share Page (the page itself is built inside Talkable)
    - Share Offer via:
      - Email
      - Facebook
      - Twitter
      - SMS
      - by copying a direct Offer link
    - Track sales via the App and reward Advocate if a sale was driven thourgh someone’s claim link
  DESC

  spec.homepage     = "https://github.com/talkable/ios-sdk"
  spec.license      = { :type => 'MIT', :file => 'LICENSE' }
  spec.author             = "Talkable"
  spec.social_media_url   = "https://twitter.com/talkable"

  spec.platform     = :ios, "9.0"

  spec.source       = { :git => "https://github.com/talkable/ios-sdk.git", :tag => "#{spec.version}" }
  spec.source_files  = "Talkable/**/*.{h,m}"
  spec.dependency 'AFNetworking', '~> 4.0'
  spec.ios.frameworks = "UIKit", "Contacts", "WebKit", "Social", "MessageUI", "Foundation", "Security", "SafariServices"

  spec.requires_arc = true
end
