//
//  Notifier.swift
//  Woojo
//
//  Created by Edouard Goossens on 23/02/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import Foundation
import Whisper
import Applozic

class Notifier {
    
    var shoutsQueue: [CurrentUser.Notification] = []
    
    static let shared = Notifier()
    
    func getTopViewController() -> UIViewController? {
        if var topViewController = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = topViewController.presentedViewController {
                topViewController = presentedViewController
            }
            return topViewController
        } else {
            return nil
        }
    }
    
    func shout() {
        if shoutsQueue.count > 0 {
            if !shouldShout(notification: shoutsQueue[0]) {
                moveQueueAndShout()
                return
            }
            if let matchNotification = shoutsQueue[0] as? CurrentUser.MatchNotification {
                announcement(notification: matchNotification) { announcement, error in
                    if let announcement = announcement {
                        self.doShout(announcement: announcement)
                    }
                }
            }
            else if let messageNotification = shoutsQueue[0] as? CurrentUser.MessageNotification {
                announcement(notification: messageNotification) { announcement, error in
                    if let announcement = announcement {
                        self.doShout(announcement: announcement)
                    }
                }
            }
        }
    }
    
    fileprivate func doShout(announcement: Announcement) {
        shout(announcement: announcement) {
            self.moveQueueAndShout()
        }
    }
    
    fileprivate func moveQueueAndShout() {
        if shoutsQueue.count > 0 {
            let notification = shoutsQueue.removeFirst()
            notification.setDisplayed()
            shout()
        }
    }
    
    func shout(announcement: Announcement, completion: (() -> Void)? = nil) {
        if let topViewController = getTopViewController() {
            DispatchQueue.main.async {
                show(shout: announcement, to: topViewController, completion: {
                    completion?()
                })
            }
        }
    }
    
    func schedule(notification: CurrentUser.Notification) {
        if shoutsQueue.count >= Constants.User.Notification.maxQueueLength {
            notification.setDisplayed()
            return
        }
        shoutsQueue.append(notification)
        if shoutsQueue.count == 1 {
            shout()
        }
    }
    
    func shouldShout(notification: CurrentUser.Notification) -> Bool {
        if let topViewController = getTopViewController() {
            if let mainTabBarController = topViewController as? MainTabBarController,
                let navigationController = mainTabBarController.selectedViewController as? NavigationController {
                if let _ = navigationController.topViewController as? MessagesViewController { return false }
                else if let chatViewController = navigationController.topViewController as? ChatViewController, let notification = notification as? CurrentUser.MessageNotification {
                    return chatViewController.contactIds != notification.otherId
                } else { return true }
            } else { return true }
        } else { return false }
    }
    
    func announcement(notification: CurrentUser.MatchNotification, completion: ((Announcement?, Error?) -> Void)? = nil) {
        let otherUser = User(uid: notification.otherId)
        otherUser.profile.loadFromFirebase { profile, error in
            if let error = error {
                print("Unable to load profile to create announcement for match notification: \(error.localizedDescription)")
                completion?(nil, error)
            } else {
                if let profile = profile,
                    let displayName = profile.displayName,
                    let photo = profile.photos.value[0] {
                    photo.download(size: .thumbnail) {
                        let announcement = Announcement(title: Constants.User.Notification.Interaction.Match.announcement.title, subtitle: "You matched with \(displayName)!", image: photo.images[.thumbnail], duration: Constants.User.Notification.Interaction.Match.announcement.duration, action: {
                                self.tapOnNotification(notification: notification)
                        })
                        completion?(announcement, nil)
                    }
                } else {
                    print("Unable to create announcement for match notification: missing some profile data.")
                    completion?(nil, nil)
                }
            }
        }
        
    }
    
    func tapOnNotification(notification: CurrentUser.Notification) {
        let topViewController = getTopViewController()
        //print("TOP VIEW CONTROLLER \(topViewController)")
        if let navigationController = topViewController as? NavigationController {
            navigationController.notification = notification
            navigationController.performSegue(withIdentifier: "unwindToMainTabBar", sender: navigationController)
        } else if let notification = notification as? CurrentUser.InteractionNotification {
            if let topViewController = topViewController as? UserDetailsViewController {
                if let mainTabBarController = topViewController.presentingViewController as? MainTabBarController {
                    topViewController.dismiss(sender: nil)
                    mainTabBarController.showChatFor(otherId: notification.otherId)
                }
            } else if let topViewController = topViewController as? UIImagePickerController,
                let navigationController = topViewController.presentingViewController as? NavigationController {
                //print("IMAGE PICKER presented by: ", navigationController)
                navigationController.notification = notification
                navigationController.performSegue(withIdentifier: "unwindToMainTabBar", sender: navigationController)
            } else if let mainTabBarController = topViewController as? MainTabBarController {
                mainTabBarController.showChatFor(otherId: notification.otherId)
            }
        }
    }
    
    func announcement(notification: CurrentUser.MessageNotification, completion: ((Announcement?, Error?) -> Void)? = nil) {
        let otherUser = User(uid: notification.otherId)
        otherUser.profile.loadFromFirebase { profile, error in
            if let error = error {
                print("Unable to load profile to create announcement for message notification: \(error.localizedDescription)")
                completion?(nil, error)
            } else {
                if let profile = profile,
                    let displayName = profile.displayName,
                    let photo = profile.photos.value[0] {
                    photo.download(size: .thumbnail) {
                        let announcement = Announcement(title: Constants.User.Notification.Interaction.Message.announcement.title, subtitle: "\(displayName): \(notification.excerpt)", image: photo.images[.thumbnail], duration: Constants.User.Notification.Interaction.Message.announcement.duration, action: {
                            self.tapOnNotification(notification: notification)
                        })
                        completion?(announcement, nil)
                    }
                } else {
                    print("Unable to create announcement for message notification: missing some profile data.")
                    completion?(nil, nil)
                }
            }
        }

    }
    
    /*func startMonitoringReachability() {
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(notification:)), name: NSNotification.Name.AL_kReachabilityChanged, object: nil)
    }
    
    @objc func reachabilityChanged(notification: Notification) {
        if let reachability = notification.object as? ALReachability {
            if reachability.isReachable() {
                print("REACHABBBBBLE")
            } else {
                print("UNREACHABBBBBLE")
            }
        }
    }*/
    
    
    
}
