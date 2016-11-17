//
//  SecondViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 03/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import LayerKit
import Atlas
import UserNotifications

class ATLChatsViewController: ATLConversationListViewController, ATLConversationListViewControllerDelegate, ATLConversationListViewControllerDataSource {
    
    @IBOutlet weak var containerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*if ([application respondsToSelector:@selector(registerForRemoteNotifications)]) {
            // Register device for iOS8
            UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
            [application registerUserNotificationSettings:notificationSettings];
            [application registerForRemoteNotifications];
        } else {
            // Register device for iOS7
            [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeBadge];
        }*/
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if error == nil {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        
        let settingsItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(showSettings))
        self.navigationItem.setRightBarButton(settingsItem, animated: false)
        self.title = "Atlas"
        self.layerClient = LayerManager.layerClient
        self.displaysAvatarItem = true
        self.dataSource = self
        self.delegate = self
        self.allowsEditing = false
        self.shouldDisplaySearchController = false // Doesn't work??
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showSettings(sender : Any?) {
        let settingsController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "settingsNavigation")
        self.present(settingsController, animated: true, completion: nil)
    }
    
    // MARK - Actions
    
    // MARK - ATLConversationListViewControllerDelegate Methods
    func conversationListViewController(_ conversationListViewController: ATLConversationListViewController, didSelect conversation:LYRConversation) {
        presentControllerWithConversation(conversation: conversation)
        print("Selected conversation")
    }
    
    func conversationListViewController(_ conversationListViewController: ATLConversationListViewController, didDelete conversation: LYRConversation, deletionMode: LYRDeletionMode) {
        print("Conversation deleted")
    }
    
    func conversationListViewController(_ conversationListViewController: ATLConversationListViewController, didFailDeleting conversation: LYRConversation, deletionMode: LYRDeletionMode, error: Error) {
        print("Failed to delete conversation with error: \(error)")
    }
    
    /*private func conversationListViewController(_ conversationListViewController: ATLConversationListViewController, didSearchForText searchText: String, completion: ((Set<NSObject>) -> Void)?) {
        UserManager.sharedManager.queryForUserWithName(searchText) { (participants: NSArray?, error: NSError?) in
            if error == nil {
                if let callback = completion {
                    callback(NSSet(array: participants as! [AnyObject]) as Set<NSObject>)
                }
            } else {
                if let callback = completion {
                    callback(nil)
                }
                print("Error searching for Users by name: \(error)")
            }
        }
    }*/
    
    func conversationListViewController(_ conversationListViewController: ATLConversationListViewController, avatarItemFor conversation: LYRConversation) -> ATLAvatarItem {
        let chatParticipant = ChatParticipant()
        for participant in conversation.participants {
            if participant.userID != layerClient.authenticatedUser?.userID {
                chatParticipant.avatarImageURL = participant.avatarImageURL
                chatParticipant.firstName = participant.firstName
            }
        }
        return chatParticipant
    }
    
    // MARK - ATLConversationListViewControllerDataSource Methods
    func conversationListViewController(_ conversationListViewController: ATLConversationListViewController, titleFor conversation: LYRConversation) -> String {
        var title = "Unknown"
        var participantStrings: [String] = []
        print("Conversation \(conversation.participants.count)")
        for participant in conversation.participants {
            if participant.userID != layerClient.authenticatedUser?.userID {
                participantStrings.append(participant.displayName)
            }
        }
        if participantStrings.count > 0 {
            title = participantStrings.joined(separator: ", ")
        }
        return title
    }
    
    func presentControllerWithConversation(conversation: LYRConversation) {
        let conversationViewController: ATLChatViewController = ATLChatViewController(layerClient: LayerManager.layerClient)
        conversationViewController.displaysAddressBar = false
        conversationViewController.conversation = conversation
        
        if self.navigationController!.topViewController == self {
            self.navigationController!.pushViewController(conversationViewController, animated: true)
        } else {
            var viewControllers = self.navigationController!.viewControllers
            let listViewControllerIndex: Int = self.navigationController!.viewControllers.index(of: self)!
            viewControllers[listViewControllerIndex + 1 ..< viewControllers.count] = [conversationViewController]
            self.navigationController!.setViewControllers(viewControllers, animated: true)
        }
    }
}

