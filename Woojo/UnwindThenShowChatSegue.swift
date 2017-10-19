//
//  SegueWithCompletion.swift
//  Woojo
//
//  Created by Edouard Goossens on 01/03/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import UIKit

class UnwindThenShowChatSegue: UIStoryboardSegue {
    
    override func perform() {
        super.perform()
        if let source = self.source as? NavigationController,
            let otherUid = source.otherUid as? String,
            let mainTabBarController = self.destination as? MainTabBarController {
            print("From NavigationController - otherId: \(otherUid)")
            mainTabBarController.showChatFor(otherUid: otherUid)
        }
    }

}
