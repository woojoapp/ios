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

class MainTabBarController: UITabBarController {
    
    let disposeBag = DisposeBag()
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDataSource()
        //ALApplozicSettings.setUnreadCountLabelBGColor(UIColor.red)
    }
    
    func setupDataSource() {
        User.current.asObservable()
            .flatMap { user -> Observable<[CurrentUser.Notification]> in
                if let currentUser = user {
                    return currentUser.notifications.asObservable()
                } else {
                    return Variable([]).asObservable()
                }
            }
            .subscribe(onNext: { notifications in
                if let eventsTabBarItem = self.tabBar.items?[0] {
                    let eventsNotifications = notifications.filter({ $0 is CurrentUser.EventsNotification })
                    eventsTabBarItem.badgeValue = (eventsNotifications.count > 0) ? "" : nil
                }
                if let peopleTabBarItem = self.tabBar.items?[1] {
                    let peopleNotifications = notifications.filter({ $0 is CurrentUser.PeopleNotification })
                    peopleTabBarItem.badgeValue = (peopleNotifications.count > 0) ? "" : nil
                }
                if let chatsTabBarItem = self.tabBar.items?[2] {
                    let interactionNotifications = notifications.filter({ $0 is CurrentUser.InteractionNotification })
                    chatsTabBarItem.badgeValue = (interactionNotifications.count > 0) ? String(interactionNotifications.count) : nil
                }
            }).addDisposableTo(disposeBag)
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
}
