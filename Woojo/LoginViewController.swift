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

/*extension UIImage {
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
}*/

class LoginViewController: UIViewController, LoginButtonDelegate {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
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
        
        /*UIGraphicsBeginImageContext(self.view.frame.size)
        #imageLiteral(resourceName: "background_square").drawInRectAspectFill(rect: self.view.bounds)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.view.backgroundColor = UIColor.init(patternImage: image!)*/
        let readPermissions: [FacebookCore.ReadPermission] = [.publicProfile,
                                                              .userFriends,
                                                              .custom("user_events"),
                                                              .custom("user_photos"),
                                                              .custom("user_location"),
                                                              .custom("user_birthday")]
        let loginButton = LoginButton(readPermissions: readPermissions)
        loginButton.delegate = self
        loginButton.center = self.view.center
        self.view.addSubview(loginButton)
        
        activityIndicator.isHidden = true
        
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
        
        /*activityDriver
            .map{ !$0 }
            .drive(self.activityIndicator.rx.isHidden)
            .addDisposableTo(disposeBag)*/
        
        // Do any additional setup after loading the view.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - LoginButtonDelegate
    
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        activityIndicator.startAnimating()
        switch result {
        case .success(_, _, let accessToken):
            print("Facebook login success")
            let credential = FIRFacebookAuthProvider.credential(withAccessToken: accessToken.authenticationToken)
            FIRAuth.auth()?.signIn(with: credential) { (user, error) in
                if let user = user {
                    print("Firebase login success \(user.uid)")
                    //self.dismiss(animated: true, completion: nil)
                }
                if let error = error {
                    print("Firebase login failure \(error.localizedDescription)")
                }
            }
        case .failed(let error):
            activityIndicator.stopAnimating()
            print("Facebook login error: \(error.localizedDescription)")
        case .cancelled:
            activityIndicator.stopAnimating()
            print("Facebook login cancelled.")
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: LoginButton) {
        Woojo.User.current.value?.logOut()
        activityIndicator.stopAnimating()
    }
    
    
    /*func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        print("Button cmpleted")
        let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
        FIRAuth.auth()?.signIn(with: credential) { (user, error) in
            if let user = user {
                print("Login success \(user.uid)")
                self.dismiss(animated: true, completion: nil)
            }
            if let error = error {
                print("Login failure \(error.localizedDescription)")
            }
        }
    }*/

}
