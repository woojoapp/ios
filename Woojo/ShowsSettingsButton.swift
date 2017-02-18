//
//  ShowsSettingsButton.swift
//  Woojo
//
//  Created by Edouard Goossens on 16/02/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol ShowsSettingsButton {
    func showSettingsButton()
    
    var disposeBag: DisposeBag { get }
    var navigationItem: UINavigationItem { get }
}

extension ShowsSettingsButton {

    func showSettingsButton() {
        
        let settingsItem = UIBarButtonItem()
        let settingsButton = UIButton(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
        
        settingsButton.layer.cornerRadius = settingsButton.frame.width / 2
        settingsButton.layer.masksToBounds = true
        settingsItem.customView = settingsButton
        
        navigationItem.setRightBarButton(settingsItem, animated: true)
        
        Woojo.User.current.asObservable()
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
                settingsButton.setImage(image, for: .normal)
            })
            .addDisposableTo(disposeBag)
        
    }
    
}