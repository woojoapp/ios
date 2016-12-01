//
//  SecondViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 03/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import Applozic
import FirebaseAuth

class ALChatsViewController: TabViewController, ALMessagesViewDelegate {
    
    @IBOutlet weak var containerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let chatManager = ALChatManager(applicationKey: "woojoa4cb24509376f2a59dd5e56caf935bf7")

        let alUser : ALUser =  ALUser();
        alUser.applicationId = ALChatManager.applicationId
        alUser.userId = FIRAuth.auth()?.currentUser?.uid.addingPercentEncoding(withAllowedCharacters: .alphanumerics)       // NOTE : +,*,? are not allowed chars in userId.
        alUser.imageLink = FIRAuth.auth()?.currentUser?.photoURL?.absoluteString    // User's profile image link.
        alUser.displayName = FIRAuth.auth()?.currentUser?.displayName  // User's Display Name
        
        ALUserDefaultsHandler.setUserId(alUser.userId)
        ALUserDefaultsHandler.setDisplayName(alUser.displayName)
        ALUserDefaultsHandler.setApplicationKey(alUser.applicationId)
        ALUserDefaultsHandler.setUserAuthenticationTypeId(Int16(APPLOZIC.rawValue))
        ALUserDefaultsHandler.setProfileImageLink(alUser.imageLink)
        
        chatManager.registerUser(alUser) { (response, error) in
            if let error = error {
                print("Failed to register Applozic user \(error)")
            } else {
                ALUserDefaultsHandler.setUserKeyString(response.userKey)
                ALUserDefaultsHandler.setDeviceKeyString(response.deviceKey)
                print("Successful Applozic user registration \(response.message), \(response.userKey), \(response.deviceKey)")
            }
        }
        
        super.setupDataSource()

    }
    
    func handleCustomAction(fromMsgVC chatView: UIViewController, andWith alMessage:ALMessage) {
        let launcherDelegate = NSClassFromString(String(describing: ALApplozicSettings.self))
        launcherDelegate?.handleCustomAction(chatView, andWith: alMessage)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let frameworkBundle = Bundle(for: ALMessagesViewController.self)
        let storyboard = UIStoryboard(name: "Applozic", bundle: frameworkBundle)
        let chatController = storyboard.instantiateViewController(withIdentifier: "ALViewController")
        showViewControllerInContainerView(chatController)
    }
    
    fileprivate func showViewControllerInContainerView(_ viewController: UIViewController){
        
        for vc in self.childViewControllers{
            vc.willMove(toParentViewController: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParentViewController()
        }
        self.addChildViewController(viewController)
        viewController.view.frame = CGRect(x: 0, y: 0, width: containerView.frame.size.width, height: containerView.frame.size.height);
        containerView.addSubview(viewController.view)
        viewController.didMove(toParentViewController: self)
        
    }
    
}
