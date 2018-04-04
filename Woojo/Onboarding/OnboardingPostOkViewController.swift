//
//  OnboardingPostOkViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 19/03/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import UIKit
import RxSwift

class OnboardingPostOkViewController: OnboardingPostBaseViewController {
    
    @IBOutlet weak var titleLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        User.current.asObservable()
            .flatMap { user -> Observable<String> in
                if let currentUser = user {
                    return currentUser.profile.firstName.asObservable()
                } else {
                    return Variable("").asObservable()
                }
            }
            .map{ String(format: NSLocalizedString("Looking good, %@!", comment: ""), $0) }
            .bind(to: titleLabel.rx.text)
            .disposed(by: disposeBag)
    }

}
