//
// Created by Edouard Goossens on 13/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import Branch
import UIKit

class ShareService {
    static let shared = ShareService()

    private init() {}

    func share(from: UIViewController?) {
        let buo = BranchUniversalObject(canonicalIdentifier: "app")
        let lp = BranchLinkProperties()
        lp.channel = "inapp"
        lp.feature = "sharing"
        buo.showShareSheet(with: lp, andShareText: NSLocalizedString("Try Woojo and match with people going to the same events as you!", comment: ""), from: from) { (activity, complete) in
            print("SHARED", activity, complete)
        }
    }
}
