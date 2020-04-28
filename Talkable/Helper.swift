//
//  Helper.swift
//  TalkableSDK
//
//  Created by Илья Костюкевич on 17.01.2020.
//  Copyright © 2020 Talkable. All rights reserved.
//

import Foundation

@objc
public class Helper: NSObject {
    public class func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        #if DEBUG
            var idx = items.startIndex
            let endIdx = items.endIndex

            repeat {
                Swift.print("[Talkable]: \(items[idx])", separator: separator, terminator: idx == (endIdx - 1) ? terminator : separator)
                idx += 1
            } while idx < endIdx
        #endif
    }

    @objc
    public class func localizedString(_ string: String, comment: String = " ") -> String {
        return NSLocalizedString(string, comment: comment)
    }
    
    @objc
    public class func getTopViewController() -> UIViewController? {
        if var topController = UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            return topController
        }
        
        return nil
    }
}
