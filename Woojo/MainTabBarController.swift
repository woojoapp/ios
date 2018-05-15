//
//  MainTabBarController.swift
//  Woojo
//
//  Created by Edouard Goossens on 07/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import PKHUD
import SDWebImage
import FirebaseAuth

class MainTabBarController: UITabBarController {
    
    let disposeBag = DisposeBag()
    private var authStateDidChangeListenerHandle: AuthStateDidChangeListenerHandle?
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDataSource()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        authStateDidChangeListenerHandle = Auth.auth().addStateDidChangeListener { auth, user in
            if user == nil {
                self.present(LoginViewController(), animated: true, completion: nil)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Auth.auth().removeStateDidChangeListener(authStateDidChangeListenerHandle!)
    }

    func setupDataSource() {
        UserNotificationRepository.shared.getNotifications()
            .subscribe(onNext: { notifications in
                if let eventsTabBarItem = self.tabBar.items?[0] {
                    let eventsNotifications = notifications.filter({ $0 is EventsNotification })
                    eventsTabBarItem.badgeValue = (eventsNotifications.count > 0) ? "" : nil
                }
                if let peopleTabBarItem = self.tabBar.items?[1] {
                    let peopleNotifications = notifications.filter({ $0 is PeopleNotification })
                    peopleTabBarItem.badgeValue = (peopleNotifications.count > 0) ? "" : nil
                }
                if let chatsTabBarItem = self.tabBar.items?[2] {
                    let interactionNotifications = notifications.filter({ $0 is InteractionNotification })
                    chatsTabBarItem.badgeValue = (interactionNotifications.count > 0) ? String(interactionNotifications.count) : nil
                }
            }, onError: { _ in
                
            }).disposed(by: disposeBag)
    }
    
    func showEvents() {
        self.selectedIndex = 0
        if let eventsNavigationController = self.selectedViewController as? UINavigationController, eventsNavigationController.topViewController is EventDetailsViewController {
                _ = eventsNavigationController.popViewController(animated: true)
        }
        HUD.hide()
    }
    
    func showPeople() {
        self.selectedIndex = 1
        HUD.hide()
    }
    
    func showChatFor(otherUid: String) {
        self.selectedIndex = 2
        if let chatsNavigationController = self.selectedViewController as? UINavigationController {
            if let chatViewController = chatsNavigationController.topViewController as? ChatViewController {
                if chatViewController.contactIds != otherUid {
                    HUD.flash(.progress, delay: 5.0)
                    _ = chatViewController.navigationController?.popViewController(animated: true)
                    if let messagesViewController = chatViewController.chatViewDelegate as? MessagesViewController {
                        messagesViewController.showAfterDidAppear = otherUid
                    }
                }
            } else if let messagesViewController = chatsNavigationController.topViewController as? MessagesViewController {
                HUD.flash(.progress, delay: 5.0)
                if messagesViewController.didAppear {
                    messagesViewController.createDetailChatViewController(otherUid)
                } else {
                    messagesViewController.showAfterDidAppear = otherUid
                }
            }
        }
    }
    
    func addWithHUD(eventId: String) {
        //HUD.show(.labeledProgress(title: NSLocalizedString("Adding Event...", comment: ""), subtitle: event.name))
        UserActiveEventRepository.shared.activateEvent(eventId: eventId).catch { _ in }
            
        /*func showImagelessSuccess() {
            HUD.show(.labeledSuccess(title: NSLocalizedString("Event added!", comment: ""), subtitle: event.name))
            HUD.hide(afterDelay: 3.0)
            Application.defferedEvent = nil
        }
        
        if let pictureURL = event.pictureURL {
            SDWebImageManager.shared().imageDownloader?.downloadImage(with: pictureURL, options: [], progress: { (_, _, _) in }, completed: { (image, _, error, finished) in
                if let image = image, error == nil, finished == true {
                    HUD.show(.labeledImage(image: image, title: NSLocalizedString("Event added!", comment: ""), subtitle: "\(event.name)"))
                    HUD.hide(afterDelay: 3.0)
                    Application.defferedEvent = nil
                } else {
                    showImagelessSuccess()
                }
            })
        } else {
            showImagelessSuccess()
        }*/
        Application.defferedEvent = nil
        let analyticsEventParameters = ["event_id": eventId,
                                        "source": "deeplink"]
        Analytics.Log(event: "Events_event_added", with: analyticsEventParameters)
    }
}
