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

protocol ShowsSettingsButton: class {
    
    func showSettingsButton()
    func showSettings(sender: Any?)
    
    var disposeBag: DisposeBag { get }
    //var navigationItem: UINavigationItem { get }
}

extension ShowsSettingsButton where Self: UIViewController {

    func showSettingsButton() {
        
        let settingsItem = UIBarButtonItem()
        let settingsButton = UIButton(frame: CGRect(x: 0, y: 0, width: 36, height: 36))
        
        let widthConstraint = settingsButton.widthAnchor.constraint(equalToConstant: 36)
        let heightConstraint = settingsButton.heightAnchor.constraint(equalToConstant: 36)
        heightConstraint.isActive = true
        widthConstraint.isActive = true
        
        settingsButton.layer.cornerRadius = settingsButton.frame.width / 2
        settingsButton.layer.masksToBounds = true
        
        settingsButton.imageView?.contentMode = .scaleAspectFill
        
        settingsItem.customView = settingsButton
        
        self.navigationItem.setRightBarButton(settingsItem, animated: true)
        
        UserProfileRepository.shared.getPhotoAsImage(position: 0, size: .thumbnail)
            .subscribe(onNext: { image in
                if let image = image { settingsButton.setImage(image, for: .normal) }
            }, onError: { _ in
                
            }).disposed(by: disposeBag)
        
    }
    
}
