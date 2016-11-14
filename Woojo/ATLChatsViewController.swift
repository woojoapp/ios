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

class ATLChatsViewController: ATLConversationListViewController, ATLConversationListViewControllerDelegate, ATLConversationListViewControllerDataSource {
    
    @IBOutlet weak var containerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let settingsItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(showSettings))
        self.navigationItem.setRightBarButton(settingsItem, animated: false)
        self.title = "Chats"
        self.displaysAvatarItem = false
        self.dataSource = self
        self.delegate = self
        self.allowsEditing = false
        self.shouldDisplaySearchController = false
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
    
    /*func conversationListViewController(conversationListViewController: ATLConversationListViewController!, avatarItemForConversation conversation: LYRConversation!) -> ATLAvatarItem! {
        guard let lastMessage = conversation.lastMessage else {
            return nil
        }
        guard let userID: String = lastMessage.sender.userID else {
            return nil
        }
        if userID == PFUser.currentUser()?.objectId {
            return PFUser.currentUser()
        }
        let user: PFUser? = UserManager.sharedManager.cachedUserForUserID(userID)
        if user == nil {
            UserManager.sharedManager.queryAndCacheUsersWithIDs([userID], completion: { (participants, error) in
                if participants != nil && error == nil {
                    self.reloadCellForConversation(conversation)
                } else {
                    print("Error querying for users: \(error)")
                }
            })
        }
        return user;
    }*/
    
    // MARK - ATLConversationListViewControllerDataSource Methods
    func conversationListViewController(_ conversationListViewController: ATLConversationListViewController, titleFor conversation: LYRConversation) -> String {
        if let title = conversation.metadata?["title"] {
            return title as! String
        } else {
            return "Conversation with \(conversation.participants.count) users..."
        }
    }
    
    func presentControllerWithConversation(conversation: LYRConversation) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let conversationViewController: ATLChatViewController = ATLChatViewController(layerClient: appDelegate.layerClient)
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

