//
//  NotificationsViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 17/11/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import UIKit
import RxSwift

class NotificationsViewController: UITableViewController {
    
    @IBOutlet weak var pushNotificationsSwitch: UISwitch!
    @IBOutlet weak var matchNotificationsSwitch: UISwitch!
    @IBOutlet weak var messageNotificationsSwitch: UISwitch!
    @IBOutlet weak var peopleNotificationsSwitch: UISwitch!
    @IBOutlet weak var eventsNotificationsSwitch: UISwitch!
    private let disposeBag = DisposeBag()
    private let viewModel = NotificationsSettingsViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }
    
    private func bindViewModel() {
        viewModel
            .getNotificationsState(type: "match")
            .asDriver(onErrorJustReturn: false)
            .drive(matchNotificationsSwitch.rx.isOn)
            .disposed(by: disposeBag)
        
        viewModel
            .getNotificationsState(type: "message")
            .asDriver(onErrorJustReturn: false)
            .drive(messageNotificationsSwitch.rx.isOn)
            .disposed(by: disposeBag)
        
        viewModel
            .getNotificationsState(type: "people")
            .asDriver(onErrorJustReturn: false)
            .drive(peopleNotificationsSwitch.rx.isOn)
            .disposed(by: disposeBag)
        
        viewModel
            .getNotificationsState(type: "events")
            .asDriver(onErrorJustReturn: false)
            .drive(eventsNotificationsSwitch.rx.isOn)
            .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.pushNotificationsSwitch.isOn = UIApplication.shared.isRegisteredForRemoteNotifications
    }
    
    @IBAction func switchNotifications(sender: UISwitch) {
        switch sender {
        case pushNotificationsSwitch:
            if sender.isOn {
                if let application = UIApplication.shared.delegate as? Woojo.Application {
                    application.requestNotifications()
                }
            } else {
                UIApplication.shared.unregisterForRemoteNotifications()
                Analytics.setUserProperties(properties: ["push_notifications_enabled": "false"])
                Analytics.Log(event: "Preferences_push_notifications", with: ["enabled": "false"])
            }
        case matchNotificationsSwitch:
            viewModel.setNotificationsState(type: "match", enabled: sender.isOn).catch { _ in }
        case messageNotificationsSwitch:
            viewModel.setNotificationsState(type: "message", enabled: sender.isOn).catch { _ in }
        case peopleNotificationsSwitch:
            viewModel.setNotificationsState(type: "people", enabled: sender.isOn).catch { _ in }
        case eventsNotificationsSwitch:
            viewModel.setNotificationsState(type: "events", enabled: sender.isOn).catch { _ in }
        default: ()
        }
    }

}
