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
        let readPermissions: [FacebookCore.ReadPermission] = [.publicProfile,
                                                              .userFriends,
                                                              .custom("user_events"),
                                                              .custom("user_photos"),
                                                              .custom("user_location"),
                                                              .custom("user_birthday"),
                                                              .custom("user_likes")]
        loginManager.logIn(readPermissions: readPermissions, viewController: self) { (loginResult) in
            self.handleLogin(result: loginResult)
        }
    }
    
    func handleLogin(result: LoginResult) {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        loginFacebook?.isHidden = true
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
                //Auth.auth().signIn(with: credential) { (user, error) in
                Auth.auth().signIn(withCustomToken: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1aWQiOiJXTVN5UW5PdHRUaFhTUmxiWTJnZ2V6UjFRVVkyIiwiaWF0IjoxNTI1MTgxMTQ3LCJleHAiOjE1MjUxODQ3NDcsImF1ZCI6Imh0dHBzOi8vaWRlbnRpdHl0b29sa2l0Lmdvb2dsZWFwaXMuY29tL2dvb2dsZS5pZGVudGl0eS5pZGVudGl0eXRvb2xraXQudjEuSWRlbnRpdHlUb29sa2l0IiwiaXNzIjoiZmlyZWJhc2UtYWRtaW5zZGstdHhwb3hAd29vam8tcHJvZHVjdGlvbi5pYW0uZ3NlcnZpY2VhY2NvdW50LmNvbSIsInN1YiI6ImZpcmViYXNlLWFkbWluc2RrLXR4cG94QHdvb2pvLXByb2R1Y3Rpb24uaWFtLmdzZXJ2aWNlYWNjb3VudC5jb20ifQ.BUBYohJy0WQdNkom0_wLrOClfX4Ph_KXj4DFeaBfq-ldyrkoSmP0u73E0d3dXBojwNFiJksx2DAC1RlcWKqgYBNj7awUVWFGnkvuliQIJW6nQ9oZrt7poDz9vZkXuJNqKhCn3mHNfRiklWvg1FKRa3sO6tQZJVicV_zpC_pmsc7lzKdXLqPh5HE_e7NWys3rEHE9CEWKi0uKArdpOce2v87cSaSxsLfxFf7bqBjHOxfcba5ilRKkqyF56vW-usndnHjHvUEDgEV125riJW8kJrLVdzywrY4KkwYnSAlZxAq4LAjkA0vfSXw-EpHquHq7VynrD5je0jLnxGJmlNAUMQ") { (user, error) in
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
