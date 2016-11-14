//
//  LoginViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 03/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKCoreKit
import FBSDKLoginKit

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

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate {
    
    var loginButton: FBSDKLoginButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIGraphicsBeginImageContext(self.view.frame.size)
        #imageLiteral(resourceName: "background_square").drawInRectAspectFill(rect: self.view.bounds)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.view.backgroundColor = UIColor.init(patternImage: image!)

        self.loginButton = FBSDKLoginButton(type: .roundedRect)
        self.loginButton.readPermissions = [ "public_profile", "user_events", "user_photos", "user_friends"]
        self.loginButton.delegate = self
        self.loginButton.center = self.view.center
        self.view.addSubview(self.loginButton)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - FBSDKLoginButtonDelegate
    
    func loginButtonWillLogin(_ loginButton: FBSDKLoginButton!) -> Bool {
        return true
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        try! FIRAuth.auth()!.signOut()
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
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
    }

}
