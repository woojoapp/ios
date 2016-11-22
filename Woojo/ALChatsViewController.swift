//
//  SecondViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 03/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import Applozic
import FirebaseAuth

class ALChatsViewController: UIViewController, ALMessagesViewDelegate {
    
    @IBOutlet weak var containerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let chatManager = ALChatManager(applicationKey: "woojoa4cb24509376f2a59dd5e56caf935bf7")

        let alUser : ALUser =  ALUser();
        alUser.applicationId = ALChatManager.applicationId
        alUser.userId = FIRAuth.auth()?.currentUser?.uid.addingPercentEncoding(withAllowedCharacters: .alphanumerics)       // NOTE : +,*,? are not allowed chars in userId.
        alUser.imageLink = FIRAuth.auth()?.currentUser?.photoURL?.absoluteString    // User's profile image link.
        alUser.displayName = FIRAuth.auth()?.currentUser?.displayName  // User's Display Name
        
        ALUserDefaultsHandler.setUserId(alUser.userId)
        ALUserDefaultsHandler.setDisplayName(alUser.displayName)
        ALUserDefaultsHandler.setApplicationKey(alUser.applicationId)
        ALUserDefaultsHandler.setUserAuthenticationTypeId(Int16(APPLOZIC.rawValue))
        ALUserDefaultsHandler.setProfileImageLink(alUser.imageLink)
        
        chatManager.registerUser(alUser) { (response, error) in
            if let error = error {
                print("Failed to register Applozic user \(error)")
            } else {
                ALUserDefaultsHandler.setUserKeyString(response.userKey)
                ALUserDefaultsHandler.setDeviceKeyString(response.deviceKey)
                print("Successful Applozic user registration \(response.message), \(response.userKey), \(response.deviceKey)")
                //let chatController = ALMessagesViewController()
                //chatController.messagesViewDelegate = self
               // self.showViewControllerInContainerView(chatController)
            }
        }
        
        let settingsItem = UIBarButtonItem()
        let settingsButton = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        settingsButton.layer.cornerRadius = settingsButton.frame.width / 2
        settingsButton.layer.masksToBounds = true
        CurrentUser.Profile.photoDownloadURL { url, error in
            if let url = url {
                settingsButton.sd_setImage(with: url, for: .normal)
            }
        }
        settingsButton.addTarget(self, action: #selector(showSettings), for: .touchUpInside)
        settingsItem.customView = settingsButton
        self.navigationItem.setRightBarButton(settingsItem, animated: true) 

    }
    
    func handleCustomAction(fromMsgVC chatView: UIViewController, andWith alMessage:ALMessage) {
        let launcherDelegate = NSClassFromString(String(describing: ALApplozicSettings.self))
        launcherDelegate?.handleCustomAction(chatView, andWith: alMessage)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showSettings(sender : Any?) {
        let settingsController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "settingsNavigation")
        self.present(settingsController, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //        setTabBarNavigationTitle("Chat")
        
        //let frameworkBundle = Bundle(identifier: "com.applozic.framework")
        let frameworkBundle = Bundle(for: ALMessagesViewController.self)
        print(frameworkBundle)
        let storyboard = UIStoryboard(name: "Applozic", bundle: frameworkBundle)
        let chatController = storyboard.instantiateViewController(withIdentifier: "ALViewController")
        showViewControllerInContainerView(chatController)
        //let chatController = ALMessagesViewController()
        //showViewControllerInContainerView(chatController)
        //        showViewController(chatController, sender: self)
    }
    
    fileprivate func showViewControllerInContainerView(_ viewController: UIViewController){
        
        for vc in self.childViewControllers{
            vc.willMove(toParentViewController: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParentViewController()
        }
        self.addChildViewController(viewController)
        viewController.view.frame = CGRect(x: 0, y: 0, width: containerView.frame.size.width, height: containerView.frame.size.height);
        containerView.addSubview(viewController.view)
        viewController.didMove(toParentViewController: self)
        
    }
    
    // MARK - Actions
    
    /*func composeButtonTapped(sender: AnyObject) {
     let appDelegate = UIApplication.shared.delegate as! AppDelegate
     let controller = ChatViewController(layerClient: appDelegate.layerClient)
     controller.displaysAddressBar = false
     self.navigationController!.pushViewController(controller, animated: true)
     }*/
    
    // MARK - ATLConversationListViewControllerDelegate Methods
    /*func conversationListViewController(_ conversationListViewController: ATLConversationListViewController, didSelect conversation:LYRConversation) {
        presentControllerWithConversation(conversation: conversation)
        print("Selected conversation")
    }
    
    func conversationListViewController(_ conversationListViewController: ATLConversationListViewController, didDelete conversation: LYRConversation, deletionMode: LYRDeletionMode) {
        print("Conversation deleted")
    }
    
    func conversationListViewController(_ conversationListViewController: ATLConversationListViewController, didFailDeleting conversation: LYRConversation, deletionMode: LYRDeletionMode, error: Error) {
        print("Failed to delete conversation with error: \(error)")
    }*/
    
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
    /*func conversationListViewController(_ conversationListViewController: ATLConversationListViewController, titleFor conversation: LYRConversation) -> String {
        if let title = conversation.metadata?["title"] {
            return title as! String
        } else {
            return "Conversation with \(conversation.participants.count) users..."
        }
    }
    
    func presentControllerWithConversation(conversation: LYRConversation) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let conversationViewController: ChatViewController = ChatViewController(layerClient: appDelegate.layerClient)
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
    }*/
}
