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
        
        self.showSettingsButton()
        let settingsButton = self.navigationItem.rightBarButtonItem?.customView as? UIButton
        settingsButton?.addTarget(self, action: #selector(showSettings(sender:)), for: .touchUpInside)        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.layer.shadowOpacity = 0.0
        navigationController?.navigationBar.titleTextAttributes = [:]
        navigationController?.navigationBar.barTintColor = nil
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = UIColor.clear
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("MESSAGES VIEW WILL DISAPPEAR.. BUT DO NOTHING")
        if self.detailChatViewController != nil {
            self.detailChatViewController.refreshMainView = true
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        // Override to prevent unsubscribing MQTT from conversation
    }
    
    func showSettings(sender : Any?) {
        let settingsNavigationController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SettingsNavigationController")
        self.present(settingsNavigationController, animated: true, completion: nil)
    }
    
}
