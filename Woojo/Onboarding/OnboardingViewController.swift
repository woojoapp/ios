//
//  OnboardingViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 19/03/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import UIKit
import BWWalkthrough

class OnboardingViewController: BWWalkthroughViewController {
    
    var showCloseAtEnd = false

    override func viewDidLoad() {
        super.viewDidLoad()
        prevButton?.layer.cornerRadius = 24
        nextButton?.layer.cornerRadius = 24
        closeButton?.layer.cornerRadius = 24
    }
    
    func showCloseButton(show: Bool) {
        super.closeButton?.isHidden = !show
    }
}
