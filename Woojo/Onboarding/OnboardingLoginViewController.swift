//
//  OnboardingLoginViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 19/03/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import FacebookCore
import FacebookLogin
import FirebaseAuth
import RxSwift
import TTTAttributedLabel
import UIKit

class OnboardingLoginViewController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var loginFacebook: UIButton!
    @IBOutlet weak var acceptLabel: TTTAttributedLabel!
    @IBOutlet weak var message1: UILabel!
    @IBOutlet weak var message2: UILabel!
    @IBOutlet weak var message3: UILabel!
    
    //let loginManager = LoginManager()
    let termsText = NSLocalizedString("Terms & Conditions", comment: "")
    let privacyText = NSLocalizedString("Privacy Policy", comment: "")
    //let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        loginFacebook.layer.cornerRadius = 10
        
        activityIndicator.isHidden = true
        
        acceptLabel.delegate = self
        acceptLabel.activeLinkAttributes = [NSAttributedStringKey.foregroundColor: UIColor.darkGray]
        acceptLabel.linkAttributes = [NSAttributedStringKey.foregroundColor: UIColor.darkGray, NSAttributedStringKey.underlineStyle: 1]
        
        if let acceptString = acceptLabel.text {
            
            let acceptNSString = NSString(string: acceptString)
            
            let termsRange = acceptNSString.range(of: termsText)
            if let termsURLString = Application.remoteConfig.configValue(forKey: Constants.App.RemoteConfig.Keys.termsURL).stringValue,
                let termsURL = URL(string: termsURLString) {
                acceptLabel.addLink(to: termsURL, with: termsRange)
            }
            
            let privacyRange = acceptNSString.range(of: privacyText)
            if let privacyURLString = Application.remoteConfig.configValue(forKey: Constants.App.RemoteConfig.Keys.privacyURL).stringValue,
                let privacyURL = URL(string: privacyURLString) {
                acceptLabel.addLink(to: privacyURL, with: privacyRange)
            }
            
        }
        
        /* let activityDriver = User.current.asObservable()
            .flatMap { user -> Observable<Bool> in
                if let currentUser = user {
                    return currentUser.isLoading.asObservable()
                } else {
                    return Variable(false).asObservable()
                }
            }
            .asDriver(onErrorJustReturn: false)
        
        activityDriver
            .drive(self.activityIndicator.rx.isAnimating)
            .disposed(by: disposeBag) */
        
        message1.layer.cornerRadius = 5
        message1.layer.masksToBounds = true
        message1.layer.borderColor = UIColor(hexString: "#00D9ED").cgColor
        message1.layer.borderWidth = 2.0
        
        message2.layer.cornerRadius = 5
        message2.layer.masksToBounds = true
        message2.layer.borderColor = UIColor(hexString: "#FFC200").cgColor
        message2.layer.borderWidth = 2.0
        
        message3.layer.cornerRadius = 5
        message3.layer.masksToBounds = true
        message3.layer.borderColor = UIColor(hexString: "#00D9ED").cgColor
        message3.layer.borderWidth = 2.0
    }
    
    @IBAction func login() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(true, forKey: "PRE_LOGIN_ONBOARDING_COMPLETED")
        userDefaults.synchronize()
        Analytics.setUserProperties(properties: ["pre_login_onboarded": "true"])
        Analytics.Log(event: "Onboarding_pre_complete")
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        loginFacebook?.isHidden = true
        LoginViewModel.shared.loginWithFacebook(viewController: self).catch { error in
            self.activityIndicator.stopAnimating()
            self.loginFacebook?.isHidden = false
            if error is LoginViewModel.LoginError {
                switch (error) {
                case .facebookPermissionsDeclined(let permissions):
                    Analytics.Log(event: "Account_log_in_missing_permissions", with: permissions)
                    showDeclinedPermissionsErrorDialog()
                }
            }
        }
    }
}

extension OnboardingLoginViewController: TTTAttributedLabelDelegate {
    
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        if let termsURLString = Application.remoteConfig.configValue(forKey: Constants.App.RemoteConfig.Keys.termsURL).stringValue,
            url.absoluteString == termsURLString {
            openPage(title: termsText, url: url)
        } else {
            if let privacyURLString = Application.remoteConfig.configValue(forKey: Constants.App.RemoteConfig.Keys.privacyURL).stringValue,
                url.absoluteString == privacyURLString {
                openPage(title: privacyText, url: url)
            }
        }
    }
    
    func openPage(title: String, url: URL?) {
        let navigationController = UINavigationController()
        if let aboutWebViewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AboutWebViewController") as? AboutWebViewController {
            aboutWebViewController.url = url
            aboutWebViewController.navigationItem.title = title
            navigationController.pushViewController(aboutWebViewController, animated: false)
            self.present(navigationController, animated: true, completion: nil)
        }
    }
    
}
