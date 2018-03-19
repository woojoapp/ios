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
    
    let loginManager = LoginManager()
    let termsText = NSLocalizedString("Terms & Conditions", comment: "")
    let privacyText = NSLocalizedString("Privacy Policy", comment: "")
    let disposeBag = DisposeBag()

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
        
        let activityDriver = User.current.asObservable()
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
            .disposed(by: disposeBag)
    }
    
    @IBAction func login() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(true, forKey: "PRE_LOGIN_ONBOARDING_COMPLETED")
        userDefaults.synchronize()
        Analytics.setUserProperties(properties: ["pre_login_onboarded": "true"])
        Analytics.Log(event: "Onboarding_pre_complete")
        let readPermissions: [FacebookCore.ReadPermission] = [.publicProfile,
                                                              .userFriends,
                                                              .custom("user_events"),
                                                              .custom("user_photos"),
                                                              .custom("user_location"),
                                                              .custom("user_birthday"),
                                                              .custom("user_likes"),
                                                              .custom("user_work_history"),
                                                              .custom("user_education_history")]
        loginManager.logIn(readPermissions: readPermissions, viewController: self) { (loginResult) in
            self.handleLogin(result: loginResult)
        }
    }
    
    func handleLogin(result: LoginResult) {
        loginFacebook?.isHidden = true
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        switch result {
        case .success(let acceptedPermissions, let declinedPermissions, let accessToken):
            var permissions: [String: String] = [:]
            for permission in acceptedPermissions {
                permissions[permission.name] = "true"
                Analytics.setUserProperties(properties: ["accepted_\(permission.name)_permission": "true"])
            }
            for permission in declinedPermissions {
                permissions[permission.name] = "false"
                Analytics.setUserProperties(properties: ["accepted_\(permission.name)_permission": "false"])
            }
            if declinedPermissions.count > 0 && (declinedPermissions.contains(Permission(name: "user_events")) || declinedPermissions.contains(Permission(name: "user_birthday"))) {
                Analytics.Log(event: "Account_log_in_missing_permissions", with: permissions)
                let alert = UIAlertController(title: NSLocalizedString("Missing permissions", comment: ""), message: NSLocalizedString("Woojo needs to know at least your birthday and access your events in order to function properly.", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: {
                    LoginManager().logOut()
                    self.activityIndicator.stopAnimating()
                    self.loginFacebook?.isHidden = false
                })
            } else {
                print("Facebook login success")
                let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.authenticationToken)
                Auth.auth().signIn(with: credential) { (user, error) in
                    if let user = user {
                        print("Firebase login success \(user.uid)")
                        Analytics.Log(event: "Account_log_in", with: permissions)
                    }
                    if let error = error {
                        print("Firebase login failure \(error.localizedDescription)")
                    }
                }
            }
        case .failed(let error):
            print("Facebook login error: \(error.localizedDescription)")
            activityIndicator.stopAnimating()
            loginFacebook?.isHidden = false
        case .cancelled:
            print("Facebook login cancelled.")
            activityIndicator.stopAnimating()
            loginFacebook?.isHidden = false
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
