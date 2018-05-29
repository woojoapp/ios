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
import PKHUD

class Notifier {
    
    var shoutsQueue: [Notification] = []
    
    static let shared = Notifier()
    
    private init() {}
    
    func shout() {
        if shoutsQueue.count > 0 {
            if !shouldShout(notification: shoutsQueue[0]) {
                moveQueueAndShout()
                return
            }
            if let matchNotification = shoutsQueue[0] as? MatchNotification {
                announcement(notification: matchNotification) { announcement, error in
                    if let announcement = announcement {
                        self.doShout(announcement: announcement)
                    }
                }
            } else if let messageNotification = shoutsQueue[0] as? MessageNotification {
                announcement(notification: messageNotification) { announcement, error in
                    if let announcement = announcement {
                        self.doShout(announcement: announcement)
                    }
                }
            }/* else if let eventsNotification = shoutsQueue[0] as? EventsNotification {
                announcement(notification: eventsNotification) { announcement, error in
                    if let announcement = announcement {
                        self.doShout(announcement: announcement)
                    }
                }
            } else if let peopleNotification = shoutsQueue[0] as? PeopleNotification {
                announcement(notification: peopleNotification) { announcement, error in
                    if let announcement = announcement {
                        self.doShout(announcement: announcement)
                    }
                }
            }*/
        }
    }
    
    fileprivate func doShout(announcement: Announcement) {
        shout(announcement: announcement) {
            self.moveQueueAndShout()
        }
    }
    
    fileprivate func moveQueueAndShout() {
        print("NOTTT MOVE QUEUE AND SHOUT", shoutsQueue.count)
        if shoutsQueue.count > 0 {
            let notification = shoutsQueue.removeFirst()
            print("NOTTT MOVE QUEUE AND SHOUT", notification.id)
            if let notificationId = notification.id {
                print("NOTTT SET DISPLAYED", notificationId)
                UserNotificationRepository.shared.setDisplayed(notificationId: notificationId).catch { _ in
                    print("NOTTT SET DISPLAYED FAILED", notificationId)
                }
                shout()
            }
        }
    }
    
    func shout(announcement: Announcement, completion: (() -> Void)? = nil) {
        if let applicationDelegate = UIApplication.shared.delegate as? Application,
            let topViewController = applicationDelegate.getTopViewController() {
            DispatchQueue.main.async {
                show(shout: announcement, to: topViewController, completion: {
                    completion?()
                })
            }
        }
    }
    
    func schedule(notification: Notification) {
        if shoutsQueue.count >= Constants.User.Notification.maxQueueLength {
            if let notificationId = notification.id {
                UserNotificationRepository.shared.setDisplayed(notificationId: notificationId).catch { _ in }
            }
            return
        }
        shoutsQueue.append(notification)
        if shoutsQueue.count == 1 {
            shout()
        }
    }
    
    func shouldShout(notification: Notification) -> Bool {
        if let applicationDelegate = UIApplication.shared.delegate as? Application,
            let topViewController = applicationDelegate.getTopViewController() {
            if notification is InteractionNotification {
                if let mainTabBarController = topViewController as? MainTabBarController,
                    let navigationController = mainTabBarController.selectedViewController as? NavigationController {
                    if navigationController.topViewController is MessagesViewController { return false }
                    else if let chatViewController = navigationController.topViewController as? ChatViewController, let notification = notification as? MessageNotification {
                        return chatViewController.contactIds != notification.otherId
                    } else { return true }
                } else { return true }
            }/* else if notification is EventsNotification {
                if let mainTabBarController = topViewController as? MainTabBarController,
                    let navigationController = mainTabBarController.selectedViewController as? NavigationController {
                    if navigationController.topViewController is EventsViewController { return false }
                    else { return true }
                } else { return true }
            } else if notification is PeopleNotification {
                if let mainTabBarController = topViewController as? MainTabBarController,
                    let navigationController = mainTabBarController.selectedViewController as? NavigationController {
                    if navigationController.topViewController is CandidatesViewController { return false }
                    else { return true }
                } else { return true }
            }*/ else { return true }
        } else { return false }
    }
    
    func announcement(notification: MatchNotification, completion: ((Announcement?, Error?) -> Void)? = nil) {
        if let otherId = notification.otherId {
            UserProfileRepository.shared.getProfile(uid: otherId).toPromise().then { profile in
                if let profile = profile,
                    let displayName = profile.firstName {
                    UserProfileRepository.shared.getPhotoAsImage(uid: otherId, position: 0, size: .thumbnail).toPromise().then { image in
                        let announcement = Announcement(title: Constants.User.Notification.Interaction.Match.announcement.title, subtitle: String(format: NSLocalizedString("You matched with %@!", comment: ""), displayName), image: image, duration: Constants.User.Notification.Interaction.Match.announcement.duration, action: {
                            self.tapOnNotification(notification: notification)
                        })
                        completion?(announcement, nil)
                    }
                } else {
                    print("Unable to create announcement for match notification: missing some profile data.")
                    completion?(nil, nil)
                }
            }.catch { error in
                print("Unable to load profile to create announcement for match notification: \(error.localizedDescription)")
                completion?(nil, error)
            }
        }
    }
    
    /*func announcement(notification: EventsNotification, completion: ((Announcement?, Error?) -> Void)? = nil) {
        if let count = notification.count {
            let announcement = Announcement(title: Constants.User.Notification.Events.announcement.title, subtitle: String(format: NSLocalizedString("Discover people in your %d new events!", comment: ""), count), image: #imageLiteral(resourceName: "events_tab_padded"), duration: Constants.User.Notification.Events.announcement.duration, action: {
                self.tapOnNotification(notification: notification)
            })
            completion?(announcement, nil)
        }
    }
    
    func announcement(notification: PeopleNotification, completion: ((Announcement?, Error?) -> Void)? = nil) {
        let announcement = Announcement(title: Constants.User.Notification.People.announcement.title, subtitle: NSLocalizedString("You have new people waiting!", comment: ""), image: #imageLiteral(resourceName: "people"), duration: Constants.User.Notification.People.announcement.duration, action: {
            self.tapOnNotification(notification: notification)
        })
        completion?(announcement, nil)
    }
    
    func tapOnNotification(notification: EventsNotification) {
        if let applicationDelegate = UIApplication.shared.delegate as? Application {
            applicationDelegate.navigateToEvents()
        }
    }
    
    func tapOnNotification(notification: PeopleNotification) {
        if let applicationDelegate = UIApplication.shared.delegate as? Application {
            applicationDelegate.navigateToPeople()
        }
    }*/
    
    func tapOnNotification(notification: InteractionNotification) {
        if let applicationDelegate = UIApplication.shared.delegate as? Application,
           let otherId = notification.otherId {
            applicationDelegate.navigateToChat(otherUid: otherId)
        }
        /*let topViewController = getTopViewController()
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
        }*/
    }
    
    func announcement(notification: MessageNotification, completion: ((Announcement?, Error?) -> Void)? = nil) {
        if let otherId = notification.otherId {
            UserProfileRepository.shared.getProfile(uid: otherId).toPromise().then { profile in
                if let profile = profile,
                   let displayName = profile.firstName {
                    UserProfileRepository.shared.getPhotoAsImage(uid: otherId, position: 0, size: .thumbnail).toPromise().then { image in
                        let announcement = Announcement(title: Constants.User.Notification.Interaction.Message.announcement.title, subtitle: "\(displayName): \(notification.excerpt ?? "")", image: image, duration: Constants.User.Notification.Interaction.Message.announcement.duration, action: {
                            self.tapOnNotification(notification: notification)
                        })
                        completion?(announcement, nil)
                        }.catch { error in
                            completion?(nil, error)
                    }
                } else {
                    print("Unable to create announcement for message notification: missing some profile data.")
                    completion?(nil, nil)
                }
            }.catch { error in
                print("Unable to load profile to create announcement for message notification: \(error.localizedDescription)")
                completion?(nil, error)
            }
        } else {
            print("Unable to create announcement for message notification: missing some profile data.")
            completion?(nil, nil)
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
