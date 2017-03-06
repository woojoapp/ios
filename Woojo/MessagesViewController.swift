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

class MessagesViewController: ALMessagesViewController, ShowsSettingsButton, UITableViewDelegate {
    
    var disposeBag = DisposeBag()
    
    var showChatAfterDidAppear: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.showSettingsButton()
        let settingsButton = self.navigationItem.rightBarButtonItem?.customView as? UIButton
        settingsButton?.addTarget(self, action: #selector(showSettings(sender:)), for: .touchUpInside)
        
        mTableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.layer.shadowOpacity = 0.0
        navigationController?.navigationBar.layer.shadowRadius = 0.0
        navigationController?.navigationBar.layer.shadowOffset = CGSize.zero
        navigationController?.navigationBar.titleTextAttributes = [:]
        navigationController?.navigationBar.barTintColor = nil
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = UIColor.clear
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.newMessageReceived), name: NSNotification.Name(rawValue: Applozic.NEW_MESSAGE_NOTIFICATION), object: nil)
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
        if let showChatAfterDidAppear = showChatAfterDidAppear {
            self.createDetailChatViewController(showChatAfterDidAppear)
            self.showChatAfterDidAppear = nil
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("MESSAGES VIEW WILL DISAPPEAR.. BUT DO NOTHING")
        if self.detailChatViewController != nil {
            self.detailChatViewController.refreshMainView = true
        }
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Applozic.NEW_MESSAGE_NOTIFICATION), object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        // Override to prevent unsubscribing MQTT from conversation
    }
    
    func showSettings(sender : Any?) {
        let settingsNavigationController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SettingsNavigationController")
        self.present(settingsNavigationController, animated: true, completion: nil)
    }
    
    func newMessageReceived() {
        print("MESSSAAAGEGE FROM MessagesViewController")
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        let unmatch = UITableViewRowAction(style: .destructive, title: "Unmatch") { action, index in
            print("Unmatching")
        }
        
        let report = UITableViewRowAction(style: .normal, title: "Report") { action, index in
            print("Reporting")
        }
        report.backgroundColor = .orange
        
        return [unmatch, report]
    }
    
}
