//
//  OnboardingPostEndViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 19/03/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import UIKit

class OnboardingPostEndViewController: OnboardingPostBaseViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var ctaButton: UIButton!
    
    var onboardingViewController: OnboardingViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        ctaButton.clipsToBounds = true
        ctaButton.layer.cornerRadius = 10
    }
    
    @IBAction
    func close() {
        onboardingViewController?.close(self)
    }

}
