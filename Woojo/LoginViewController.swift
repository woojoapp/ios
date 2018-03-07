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

extension UIImage {
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
}

class LoginViewController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var facebookLabel: UILabel!
    @IBOutlet weak var acceptLabel: TTTAttributedLabel!
    @IBOutlet weak var smallPrintView: UIView!
    
    let termsText = NSLocalizedString("Terms & Conditions", comment: "")
    let privacyText = NSLocalizedString("Privacy Policy", comment: "")
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIGraphicsBeginImageContext(UIScreen.main.bounds.size)
        #imageLiteral(resourceName: "login_bg").drawInRectAspectFill(rect: UIScreen.main.bounds)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.view.backgroundColor = UIColor.init(patternImage: image!)
        
        let readPermissions: [FacebookCore.ReadPermission] = [.publicProfile,
                                                              .userFriends,
                                                              .custom("user_events"),
                                                              .custom("user_photos"),
                                                              .custom("user_location"),
                                                              .custom("user_birthday"),
                                                              .custom("user_likes")]
        let loginButton = LoginButton(readPermissions: readPermissions)
        loginButton.delegate = self
        loginButton.center = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
        self.view.addSubview(loginButton)
        
        activityIndicator.isHidden = true
        
        smallPrintView.layer.cornerRadius = 10.0
        
        acceptLabel.delegate = self
        acceptLabel.activeLinkAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        acceptLabel.linkAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.underlineStyle: 1]
        
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
}

// MARK: - LoginButtonDelegate

extension LoginViewController: LoginButtonDelegate {
    
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
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
    }

}

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
