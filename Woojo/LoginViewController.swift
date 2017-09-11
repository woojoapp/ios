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
    
    let termsText = "Terms & Conditions"
    let privacyText = "Privacy Policy"
    
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
                                                              .custom("user_birthday")]
        let loginButton = LoginButton(readPermissions: readPermissions)
        loginButton.delegate = self
        loginButton.center = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
        self.view.addSubview(loginButton)
        
        activityIndicator.isHidden = true
        
        smallPrintView.layer.cornerRadius = 10.0
        
        acceptLabel.delegate = self
        acceptLabel.activeLinkAttributes = [NSForegroundColorAttributeName: UIColor.white]
        acceptLabel.linkAttributes = [NSForegroundColorAttributeName: UIColor.white, NSUnderlineStyleAttributeName: 1]
        
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
        
        let activityDriver = Woojo.User.current.asObservable()
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
            .addDisposableTo(disposeBag)
    }

}

// MARK: - LoginButtonDelegate

extension LoginViewController: LoginButtonDelegate {
    
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        activityIndicator.startAnimating()
        switch result {
        case .success(_, _, let accessToken):
            print("Facebook login success")
            let credential = FIRFacebookAuthProvider.credential(withAccessToken: accessToken.authenticationToken)
            FIRAuth.auth()?.signIn(with: credential) { (user, error) in
                if let user = user {
                    print("Firebase login success \(user.uid)")
                }
                if let error = error {
                    print("Firebase login failure \(error.localizedDescription)")
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
        Woojo.User.current.value?.logOut()
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
