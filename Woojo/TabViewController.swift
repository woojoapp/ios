//
//  NavigationController.swift
//  Woojo
//
//  Created by Edouard Goossens on 30/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class TabViewController: UIViewController {
    
    let settingsItem = UIBarButtonItem()
    let settingsButton = UIButton(frame: CGRect(x: 0, y: 0, width: 36, height: 36))
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        settingsButton.layer.cornerRadius = settingsButton.frame.width / 2
        settingsButton.layer.masksToBounds = true
        settingsButton.addTarget(self, action: #selector(showSettings), for: .touchUpInside)
        settingsItem.customView = settingsButton
        self.navigationItem.setRightBarButton(settingsItem, animated: true)
        
    }
    
    func setupDataSource() {
        Woojo.User.current.asObservable()
            .flatMap { user -> Observable<UIImage> in
                if let currentUser = user {
                    return currentUser.profile.photo.asObservable()
                } else {
                    return Variable(#imageLiteral(resourceName: "placeholder_40x40")).asObservable()
                }
            }
            .subscribe(onNext: { image in
                self.settingsButton.setImage(image, for: .normal)
            })
            .addDisposableTo(disposeBag)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showSettings(sender : Any?) {
        let navigationController = UINavigationController()
        let settingsViewController = SettingsViewController(nibName: "SettingsViewController", bundle: nil)
        navigationController.pushViewController(settingsViewController, animated: false)
        self.present(navigationController, animated: true, completion: nil)
    }

}
