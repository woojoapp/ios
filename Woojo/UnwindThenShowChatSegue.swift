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
            //let otherUid = source.otherUid,
            let navigationDestination = source.navigationDestination,
            let mainTabBarController = self.destination as? MainTabBarController {
            print("From NavigationController - navigationDestination: \(navigationDestination)")
            if navigationDestination == "events" {
                mainTabBarController.showEvents()
            } else if navigationDestination == "people" {
                mainTabBarController.showPeople()
            } else {
                mainTabBarController.showChatFor(otherUid: navigationDestination)
            }
        }
    }
}
