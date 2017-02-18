//
//  MessagesViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 15/02/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import UIKit
import Applozic
import FirebaseAuth
import RxSwift

class MessagesViewController: ALMessagesViewController, ShowsSettingsButton {
    
    var disposeBag = DisposeBag()
    
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
        
        self.showSettingsButton()
        let settingsButton = self.navigationItem.rightBarButtonItem?.customView as? UIButton
        settingsButton?.addTarget(self, action: #selector(showSettings(sender:)), for: .touchUpInside)        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.layer.shadowOpacity = 0.0
        self.navigationController?.navigationBar.titleTextAttributes = [:]
    }
    
    func showSettings(sender : Any?) {
        let settingsNavigationController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SettingsNavigationController")
        self.present(settingsNavigationController, animated: true, completion: nil)
    }
    
}
