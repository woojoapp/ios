//
//  AppDelegate.swift
//  Woojo
//
//  Created by Edouard Goossens on 03/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseDatabase
import FirebaseAuth
import FirebaseMessaging
import FirebaseRemoteConfig
import FacebookCore
import FacebookLogin
import PKHUD
import Applozic
import RxSwift
import RxCocoa
import Whisper
import UserNotifications
import Branch
import SDWebImage
import Crashlytics
import Amplitude_iOS
import AdSupport

@UIApplicationMain
class Application: UIResponder {
    var window: UIWindow?
    let loginViewController = LoginViewController(nibName: "LoginViewController", bundle: nil)
    static var remoteConfig: RemoteConfig = RemoteConfig.remoteConfig()
    let disposeBag = DisposeBag()
    static var defferedEvent: Event?
    let notifier = Notifier.shared
    
    func requestNotifications() {
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in })
        }
        //UIApplication.shared.registerForRemoteNotifications()
    }
    
    func getTopViewController() -> UIViewController? {
        if var topViewController = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = topViewController.presentedViewController {
                if presentedViewController is UIAlertController { break }
                topViewController = presentedViewController
            }
            return topViewController
        } else { return nil }
    }
    
    func navigateToChat(otherUid: String) {
        let topViewController = getTopViewController()
        if let navigationController = topViewController as? NavigationController {
            navigationController.navigationDestination = otherUid
            navigationController.performSegue(withIdentifier: "unwindToMainTabBar", sender: navigationController)
        } else if let topViewController = topViewController as? UserDetailsViewController {
            if let mainTabBarController = topViewController.presentingViewController as? MainTabBarController {
                topViewController.dismiss(sender: nil)
                mainTabBarController.showChatFor(otherUid: otherUid)
            }
        } else if let topViewController = topViewController as? UIImagePickerController,
            let navigationController = topViewController.presentingViewController as? NavigationController {
            navigationController.navigationDestination = otherUid
            navigationController.performSegue(withIdentifier: "unwindToMainTabBar", sender: navigationController)
        } else if let mainTabBarController = topViewController as? MainTabBarController {
            mainTabBarController.showChatFor(otherUid: otherUid)
        }
    }
    
    /*func navigateToEvents() {
        let topViewController = getTopViewController()
        if let navigationController = topViewController as? NavigationController {
            navigationController.navigationDestination = "events"
            navigationController.performSegue(withIdentifier: "unwindToMainTabBar", sender: navigationController)
        } else if let topViewController = topViewController as? UserDetailsViewController {
            if let mainTabBarController = topViewController.presentingViewController as? MainTabBarController {
                topViewController.dismiss(sender: nil)
                mainTabBarController.showEvents()
            }
        } else if let topViewController = topViewController as? UIImagePickerController,
            let navigationController = topViewController.presentingViewController as? NavigationController {
            navigationController.navigationDestination = "events"
            navigationController.performSegue(withIdentifier: "unwindToMainTabBar", sender: navigationController)
        } else if let mainTabBarController = topViewController as? MainTabBarController {
            if let navigationController = mainTabBarController.selectedViewController as? NavigationController,
                let chatViewController = navigationController.topViewController as? ChatViewController {
                //HUD.flash(.progress, delay: 5.0)
                if let messagesViewController = chatViewController.chatViewDelegate as? MessagesViewController {
                    messagesViewController.showAfterDidAppear = "events"
                }
                navigationController.popViewController(animated: true)
            } else {
                mainTabBarController.showEvents()
            }
        }
    }
    
    func navigateToPeople() {
        let topViewController = getTopViewController()
        if let navigationController = topViewController as? NavigationController {
            navigationController.navigationDestination = "people"
            navigationController.performSegue(withIdentifier: "unwindToMainTabBar", sender: navigationController)
        } else if let topViewController = topViewController as? UserDetailsViewController {
            if let mainTabBarController = topViewController.presentingViewController as? MainTabBarController {
                topViewController.dismiss(sender: nil)
                mainTabBarController.showPeople()
            }
        } else if let topViewController = topViewController as? UIImagePickerController,
            let navigationController = topViewController.presentingViewController as? NavigationController {
            navigationController.navigationDestination = "people"
            navigationController.performSegue(withIdentifier: "unwindToMainTabBar", sender: navigationController)
        } else if let mainTabBarController = topViewController as? MainTabBarController {
            if let navigationController = mainTabBarController.selectedViewController as? NavigationController,
                let chatViewController = navigationController.topViewController as? ChatViewController {
                //HUD.flash(.progress, delay: 5.0)
                if let messagesViewController = chatViewController.chatViewDelegate as? MessagesViewController {
                    messagesViewController.showAfterDidAppear = "people"
                }
                navigationController.popViewController(animated: true)
            } else {
                mainTabBarController.showPeople()
            }
        }
    }*/
    
    func handlePushNotificationTap(notificationId: String, completionHandler: (() -> Void)?) {
        HUD.flash(.progress, delay: 10.0) // Show a progress HUD while Firebase synchronises data and retrieves notifications
        /*Woojo.User.current.asObservable().takeWhile({ $0 == nil }).subscribe(onCompleted: {
            Woojo.User.current.value?.notifications.asObservable().takeWhile({ (notifications) -> Bool in
                return !notifications.contains(where: { $0.id == notificationId })
            }).subscribe(onCompleted: {
                let notification = Woojo.User.current.value?.notifications.value.first(where: { $0.id == notificationId })
                if let notification = notification as? CurrentUser.InteractionNotification {
                    Notifier.shared.tapOnNotification(notification: notification)
                } else if let notification = notification as? CurrentUser.EventsNotification {
                    Notifier.shared.tapOnNotification(notification: notification)
                } else if let notification = notification as? CurrentUser.PeopleNotification {
                    Notifier.shared.tapOnNotification(notification: notification)
                }
                completionHandler?()
            }).disposed(by: self.disposeBag)
        }).disposed(by: self.disposeBag)*/
    }
    
    // MARK: - Remote config
    
    func setupRemoteConfig() {
        
        func activateDebugMode() {
            let debugSettings = RemoteConfigSettings(developerModeEnabled: true)
            Application.remoteConfig.configSettings = debugSettings!
        }
        
        let defaults: [String:NSObject] = [
            Constants.App.RemoteConfig.Keys.termsURL:"https://www.woojo.ooo/terms_app.html" as NSObject,
            Constants.App.RemoteConfig.Keys.privacyURL:"https://www.woojo.ooo/privacy_app.html" as NSObject
        ]
        // Change next 2 lines for production
        activateDebugMode()
        let expirationDuration: TimeInterval = 0
        
        Application.remoteConfig.setDefaults(defaults as [String : NSObject]?)
        Application.remoteConfig.fetch(withExpirationDuration: expirationDuration, completionHandler: { status, error in
            print("Remote config", status.rawValue)
            if status == RemoteConfigFetchStatus.success {
                Application.remoteConfig.activateFetched()
            }
            if let error = error {
                print("Failed to fetch remote config: \(error.localizedDescription)")
            }
        })
    }
    
    func startListeningForNotifications() {
        UserNotificationRepository.shared
            .addedNotifications()
            .filter { !($0.displayed ?? false) }
            .subscribe(onNext: { Notifier.shared.schedule(notification: $0) }, onError: { _ in })
            .disposed(by: disposeBag)
        
        UserNotificationRepository.shared
            .getNotifications()            
            .map { $0.count }
            .asDriver(onErrorJustReturn: 0)
            .drive(onNext: { UIApplication.shared.applicationIconBadgeNumber = $0 })
            .disposed(by: disposeBag)
    }
}

