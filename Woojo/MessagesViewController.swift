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
import PKHUD

class MessagesViewController: ALMessagesViewController, ShowsSettingsButton, UIGestureRecognizerDelegate/*, UITableViewDelegate*/ {
    
    var disposeBag = DisposeBag()
    
    var showAfterDidAppear: String?
    var didAppear = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.showSettingsButton()
        let settingsButton = self.navigationItem.rightBarButtonItem?.customView as? UIButton
        settingsButton?.addTarget(self, action: #selector(showSettings(sender:)), for: .touchUpInside)
        
        for case let cell as ALContactCell in self.mTableView.visibleCells {
            cell.mUserImageView.contentMode = .scaleAspectFill
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        /*if self.detailChatViewController != nil {
            self.detailChatViewController.refreshMainView = true
        }*/
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.layer.shadowOpacity = 0.0
        navigationController?.navigationBar.layer.shadowRadius = 0.0
        navigationController?.navigationBar.layer.shadowOffset = CGSize.zero
        navigationController?.navigationBar.titleTextAttributes = [:]
        navigationController?.navigationBar.barTintColor = nil
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = UIColor.clear
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.newMessageReceived), name: NSNotification.Name(rawValue: Applozic.NEW_MESSAGE_NOTIFICATION), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(enteredForeground), name: NSNotification.Name(rawValue: "APP_ENTER_IN_FOREGROUND"), object: nil)
        
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        
        reloadData()
        
        UserRepository.shared.setLastSeen(date: Date())
    }
    
    @objc func enteredForeground() {
        reloadData()
        viewDidAppear(true)
    }
    
    func reloadData() {
        ALMessageService.getLatestMessage(forUser: ALUserDefaultsHandler.getDeviceKeyString()) { (_, _) in }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Forcefully disable Applozic notifications
        if let window = UIApplication.shared.keyWindow?.subviews {
            for view in window {
                if let view = view as? TSMessageView {
                    view.isHidden = true
                    view.removeFromSuperview()
                }
            }
        }
        if let showAfterDidAppear = showAfterDidAppear {
            if showAfterDidAppear == "events" {
                if let mainTabBarController = self.tabBarController as? MainTabBarController {
                    mainTabBarController.selectedIndex = 0
                }
            } else if showAfterDidAppear == "people" {
                if let mainTabBarController = self.tabBarController as? MainTabBarController {
                    mainTabBarController.selectedIndex = 1
                }
            } else {
                self.createDetailChatViewController(showAfterDidAppear)
            }
            self.showAfterDidAppear = nil
        }
        didAppear = true
        HUD.hide()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("MESSAGES VIEW WILL DISAPPEAR.. BUT DO NOTHING")
        /*if self.detailChatViewController != nil {
            self.detailChatViewController.refreshMainView = true
        }*/
        //NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Applozic.NEW_MESSAGE_NOTIFICATION), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "APP_ENTER_IN_FOREGROUND"), object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        // Override to prevent unsubscribing MQTT from conversation
        didAppear = false
    }
    
    @objc func showSettings(sender : Any?) {
        let settingsNavigationController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SettingsNavigationController")
        self.present(settingsNavigationController, animated: true, completion: nil)
    }
    
    @objc func newMessageReceived() {
        print("MESSSAAAGEGE FROM MessagesViewController")
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        let unmatch = UITableViewRowAction(style: .destructive, title: NSLocalizedString("Unmatch", comment: "")) { action, index in
            if let cell = tableView.cellForRow(at: editActionsForRowAt) as? ALContactCell {
                
            }
        }
        
        let report = UITableViewRowAction(style: .normal, title: NSLocalizedString("Report", comment: "")) { action, index in
            print("Reporting")
        }
        report.backgroundColor = .orange
        
        if let cell = tableView.cellForRow(at: editActionsForRowAt) as? ALContactCell,
            let userName = cell.mUserNameLabel.text {
            if userName.range(of: "from Woojo") == nil {
                //return [unmatch, report]
                return []
            }
        }
        
        return []
    }
    
}
