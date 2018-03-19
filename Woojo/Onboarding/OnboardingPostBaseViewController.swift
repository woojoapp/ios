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
        
        User.current.asObservable()
            .flatMap { user -> Observable<[User.Profile.Photo?]> in
                if let currentUser = user {
                    return currentUser.profile.photos.asObservable()
                } else {
                    return Variable([nil]).asObservable()
                }
            }
            .map { photos -> UIImage in
                if let profilePhoto = photos[0], let image = profilePhoto.images[User.Profile.Photo.Size.thumbnail] {
                    return image
                } else {
                    return #imageLiteral(resourceName: "placeholder_40x40")
                }
            }
            .subscribe(onNext: { image in
                self.profileImageView?.contentMode = .scaleAspectFill
                self.profileImageView.image = image
            })
            .disposed(by: disposeBag)
    }
    
    override func viewDidLayoutSubviews() {
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.clipsToBounds = true
    }
}
