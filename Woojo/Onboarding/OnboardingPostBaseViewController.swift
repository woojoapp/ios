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
        
        let userPhotos = User.current.asObservable()
            .flatMap { user -> Observable<[User.Profile.Photo?]> in
                if let currentUser = user {
                    return currentUser.profile.photos.asObservable()
                } else {
                    return Variable([nil]).asObservable()
                }
        }
        
        userPhotos.subscribe(onNext: { photos in
            if let profilePhoto = photos[0] {
                if let image = profilePhoto.images[User.Profile.Photo.Size.thumbnail] {
                    self.profileImageView.image = image
                } else {
                    profilePhoto.download(size: .thumbnail) {
                        self.profileImageView.image = profilePhoto.images[User.Profile.Photo.Size.thumbnail]
                    }
                }
            } else {
                self.profileImageView.image = #imageLiteral(resourceName: "placeholder_40x40")
            }
        }).disposed(by: disposeBag)
    }
    
    override func viewDidLayoutSubviews() {
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.clipsToBounds = true
    }
}
