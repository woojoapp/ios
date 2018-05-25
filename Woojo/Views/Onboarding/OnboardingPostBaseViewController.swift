//
//  OnboardingPostBaseViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 19/03/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import UIKit
import RxSwift

class OnboardingPostBaseViewController: UIViewController {
    
    @IBOutlet weak var profileImageView: UIImageView!
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserProfileRepository.shared.getPhoto(position: 0, size: .full).subscribe(onNext: { photo in
            if let photo = photo {
                self.profileImageView.sd_setImage(with: photo)
            }
        }, onError: { _ in
            
        }).disposed(by: disposeBag)
    }
    
    override func viewDidLayoutSubviews() {
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.clipsToBounds = true
    }
}
