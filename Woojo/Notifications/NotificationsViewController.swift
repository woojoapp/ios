//
//  NotificationsViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 17/11/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import UIKit
import RxSwift
import UserNotifications

class NotificationsViewController: UITableViewController {
    
    @IBOutlet weak var managePushNotificationsButton: UIButton!
    @IBOutlet weak var matchNotificationsSwitch: UISwitch!
    @IBOutlet weak var messageNotificationsSwitch: UISwitch!
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setPushNotificationsButton()
    }
    
    private func setPushNotificationsButton() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .notDetermined {
                    self.managePushNotificationsButton.setTitle(R.string.localizable.turnOnPushNotifications(), for: .normal)
                } else {
                    self.managePushNotificationsButton.setTitle(R.string.localizable.managePushNotifications(), for: .normal)
                }
            }
        }
    }
    
    @IBAction func switchNotifications(sender: UISwitch) {
        switch sender {
        case matchNotificationsSwitch:
            viewModel.setNotificationsState(type: "match", enabled: sender.isOn).catch { _ in }
        case messageNotificationsSwitch:
            viewModel.setNotificationsState(type: "message", enabled: sender.isOn).catch { _ in }
        default: ()
        }
    }
    
    @IBAction func openNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .alert], completionHandler: { granted, _ in
                    DispatchQueue.main.async {
                        self.managePushNotificationsButton.setTitle(R.string.localizable.managePushNotifications(), for: .normal)
                    }
                })
            } else {
                DispatchQueue.main.async {
                    if let settingsUrl = URL(string: UIApplicationOpenSettingsURLString), UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
                    }
                }
            }
        }
    }

}
