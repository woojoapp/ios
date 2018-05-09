//
//  LoginViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 03/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import FirebaseAuth
import FacebookCore
import FacebookLogin
import RxCocoa
import RxSwift
import TTTAttributedLabel
import Crashlytics
import BWWalkthrough
import Amplitude_iOS

/* extension UIImage {
    func drawInRectAspectFill(rect: CGRect) {
        let targetSize = rect.size
        if targetSize == CGSize.zero {
            return self.draw(in: rect)
        }
        let widthRatio    = targetSize.width  / self.size.width
        let heightRatio   = targetSize.height / self.size.height
        let scalingFactor = max(widthRatio, heightRatio)
        let newSize = CGSize(width:  self.size.width  * scalingFactor,
                             height: self.size.height * scalingFactor)
        UIGraphicsBeginImageContext(targetSize)
        let origin = CGPoint(x: (targetSize.width  - newSize.width)  / 2,
                             y: (targetSize.height - newSize.height) / 2)
        self.draw(in: CGRect(origin: origin, size: newSize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        scaledImage?.draw(in: rect)
    }
} */

class LoginViewController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    // @IBOutlet weak var facebookLabel: UILabel!
    @IBOutlet weak var acceptLabel: TTTAttributedLabel!
    @IBOutlet var loginFacebook: UIButton!
    // @IBOutlet weak var smallPrintView: UIView!
    
    var onboardingViewController: OnboardingViewController?
    
    let loginManager = LoginManager()
    let termsText = NSLocalizedString("Terms & Conditions", comment: "")
    let privacyText = NSLocalizedString("Privacy Policy", comment: "")
    
    let slideNames = [
        "onboarding_welcome",
        "onboarding_events",
        "onboarding_swipe",
        "onboarding_login"
    ]
    
    var authListenerHandle: AuthStateDidChangeListenerHandle?
    
    override var modalTransitionStyle: UIModalTransitionStyle {
        get {
            return .flipHorizontal
        }
        set {
            super.modalTransitionStyle = .flipHorizontal
        }
    }
    
    let disposeBag = DisposeBag()
    var loginView: UIView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func showOnboarding() {
        let onboardingStoryboard = UIStoryboard(name: "Onboarding", bundle: nil)
        if let onboarding = onboardingStoryboard.instantiateViewController(withIdentifier: "Onboarding0") as? OnboardingViewController {
            onboardingViewController = onboarding
            let welcome = onboardingStoryboard.instantiateViewController(withIdentifier: "Onboarding_welcome")
            let events = onboardingStoryboard.instantiateViewController(withIdentifier: "Onboarding_events")
            let swipe = onboardingStoryboard.instantiateViewController(withIdentifier: "Onboarding_swipe")
            let login = onboardingStoryboard.instantiateViewController(withIdentifier: "Onboarding_login")
            
            onboarding.delegate = self
            onboarding.add(viewController:welcome)
            onboarding.add(viewController:events)
            onboarding.add(viewController:swipe)
            onboarding.add(viewController:login)
            
            onboarding.modalPresentationStyle = .custom
            onboarding.modalTransitionStyle = .crossDissolve
            
            self.present(onboarding, animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // UIGraphicsBeginImageContext(UIScreen.main.bounds.size)
        // #imageLiteral(resourceName: "login_bg").drawInRectAspectFill(rect: UIScreen.main.bounds)
        // let image = UIGraphicsGetImageFromCurrentImageContext()
        // UIGraphicsEndImageContext()
        // self.view.backgroundColor = UIColor.init(patternImage: image!)
        
        /* let readPermissions: [FacebookCore.ReadPermission] = [.publicProfile,
                                                              .userFriends,
                                                              .custom("user_events"),
                                                              .custom("user_photos"),
                                                              .custom("user_location"),
                                                              .custom("user_birthday"),
                                                              .custom("user_likes"),
                                                              .custom("user_work_history"),
                                                              .custom("user_education_history")] */
        /* let loginButton = LoginButton(readPermissions: readPermissions)
        loginButton.delegate = self
        loginButton.center = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
        self.view.addSubview(loginButton) */
        
        activityIndicator.isHidden = true
        
        // smallPrintView.layer.cornerRadius = 10.0
        
        acceptLabel.delegate = self
        acceptLabel.activeLinkAttributes = [NSAttributedStringKey.foregroundColor: UIColor.darkGray]
        acceptLabel.linkAttributes = [NSAttributedStringKey.foregroundColor: UIColor.darkGray, NSAttributedStringKey.underlineStyle: 1]
        
        loginFacebook.layer.cornerRadius = 10
        
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
        
        let userDefaults = UserDefaults.standard
        if !userDefaults.bool(forKey: "PRE_LOGIN_ONBOARDING_COMPLETED") {
            loginFacebook.isHidden = true
            acceptLabel.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let userDefaults = UserDefaults.standard
        if !userDefaults.bool(forKey: "PRE_LOGIN_ONBOARDING_COMPLETED") {
            showOnboarding()
        } else {
            acceptLabel.isHidden = false
        }
    }
    
    func setWorking(working: Bool) {
        loginFacebook.isHidden = working
        if working {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
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
        setWorking(working: true)
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
                    self.loginManager.logOut()
                    self.setWorking(working: false)
                })
            } else {
                print("Facebook login success here", accessToken.authenticationToken)
                let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.authenticationToken)
                Auth.auth().signIn(with: credential) { (user, error) in
                    if let user = user {
                        print("Firebase login success \(user.uid)")
                        Analytics.Log(event: "Account_log_in", with: permissions)
                    }
                    if let error = error {
                        print("Firebase login failure \(error.localizedDescription)")
                        self.setWorking(working: false)
                    }
                }
            }
        case .failed(let error):
            print("Facebook login error: \(error.localizedDescription)")
            self.setWorking(working: false)
        case .cancelled:
            print("Facebook login cancelled.")
            self.setWorking(working: false)
        }
    }
    
    func dismissOnboarding() {
        onboardingViewController?.dismiss(animated: true, completion: nil)
    }
}

// MARK: - LoginButtonDelegate

// extension LoginViewController: LoginButtonDelegate {
    
    /* func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
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
                })
            } else {
                print("Facebook login success")
                let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.authenticationToken)
                Auth.auth().signIn(with: credential) { (user, error) in
                    if let user = user {
                        print("Firebase login success \(user.uid)")
                        Analytics.Log(event: "Account_log_in", with: permissions)
                        //self.dismiss(animated: true, completion: nil)
                    }
                    if let error = error {
                        print("Firebase login failure \(error.localizedDescription)")
                    }
                }
            }
        case .failed(let error):
            print("Facebook login error: \(error.localizedDescription)")
            activityIndicator.stopAnimating()
        case .cancelled:
            print("Facebook login cancelled.")
            activityIndicator.stopAnimating()
        }
    }
    

    
    func loginButtonDidLogOut(_ loginButton: LoginButton) {
        User.current.value?.logOut()
        activityIndicator.stopAnimating()
    }*/

// }

// MARK: - TTTAttributedLabelDelegate

extension LoginViewController: TTTAttributedLabelDelegate {
    
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

// MARK: BWWalkthroughViewControllerDelegate

extension LoginViewController: BWWalkthroughViewControllerDelegate {
    func walkthroughPageDidChange(_ pageNumber: Int) {
        let parameters = ["slide_name": slideNames[pageNumber]]
        Analytics.Log(event: "Onboarding_view_slide", with: parameters)
    }
}
