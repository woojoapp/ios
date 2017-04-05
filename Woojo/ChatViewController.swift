//
//  ChatViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 15/02/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import Applozic
import SDWebImage
import PKHUD
import Whisper

class ChatViewController: ALChatViewController {
    
    @IBOutlet weak var loadEarlierAction: UIButton!
    @IBOutlet weak var loadEarlierActionTopConstraint: NSLayoutConstraint!
    
    let translucentColor = UIColor(red: 247.0/255.0, green: 247.0/255.0, blue: 247.0/255.0, alpha: 0.95)
    
    override var individualLaunch: Bool {
        get {
            return false
        }
        set {
            super.individualLaunch = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.placeHolderTxt = "Write a message..."
        ALApplozicSettings.setColorForSendMessages(self.view.tintColor)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.layer.shadowOpacity = 0.0
        navigationController?.navigationBar.layer.shadowRadius = 0.0
        navigationController?.navigationBar.layer.shadowOffset = CGSize.zero
        navigationController?.navigationBar.tintColor = nil
        navigationController?.navigationBar.barTintColor = nil
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        typingMessageView.backgroundColor = translucentColor
        sendMessageTextView.backgroundColor = UIColor.clear
        sendButton.backgroundColor = UIColor.clear
        
        let profileItem = UIBarButtonItem()
        
        let profileButton = UIButton(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
        profileButton.backgroundColor = UIColor.clear
        if let contactImageUrl = alContact.contactImageUrl {
            SDWebImageManager.shared().downloadImage(with: URL(string: contactImageUrl), options: [], progress: nil, completed: { image, _, _, _, _ in
                if let image = image {
                    profileButton.setImage(image, for: .normal)
                }
            })
        }
        profileButton.layer.cornerRadius = profileButton.frame.width / 2
        profileButton.layer.masksToBounds = true
        profileItem.customView = profileButton
        
        profileButton.addTarget(self, action: #selector(showProfile), for: .touchUpInside)
        
        navigationItem.setRightBarButton(profileItem, animated: true)
        setNavigationItemTitle()
        
        label.textColor = label.textColor.withAlphaComponent(0.6)
        
        mTableView.backgroundColor = UIColor.white
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        //NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newMessage), name: NSNotification.Name(rawValue: Applozic.NEW_MESSAGE_NOTIFICATION), object: nil)
        
    }
    
    func setNavigationItemTitle() {
        let button = navigationItem.titleView as! UIButton
        if let title = button.title(for: .normal) {
            let titleString = NSAttributedString(string: title, attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17.0)])
            button.setAttributedTitle(titleString, for: .normal)
            button.setAttributedTitle(titleString, for: .focused)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let button = navigationItem.titleView as! UIButton
        if let title = button.title(for: .normal) {
            let titleString = NSAttributedString(string: title, attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17.0)])
            button.setAttributedTitle(titleString, for: .normal)
            button.setAttributedTitle(titleString, for: .focused)
        }
        
        loadEarlierAction.backgroundColor = translucentColor
        let titleString = NSAttributedString(string: "Load earlier messages", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 12.0), NSForegroundColorAttributeName: self.view.tintColor])
        loadEarlierAction.setAttributedTitle(titleString, for: .normal)
        let bottomBorder = UIView(frame: CGRect(x: 0, y: loadEarlierAction.frame.height - 4, width: loadEarlierAction.frame.width, height: 1))
        bottomBorder.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        loadEarlierAction.addSubview(bottomBorder)
        if let navigationController = navigationController {
            loadEarlierActionTopConstraint.constant = UIApplication.shared.statusBarFrame.height + navigationController.navigationBar.frame.height
        }
        
        CurrentUser.Notification.deleteAll(otherId: self.contactIds)
        
        HUD.hide()
        
        if let uid = User.current.value?.uid,
            let analyticsEventParameters = [Constants.Analytics.Events.ChatDisplayed.Parameters.uid: uid,
                                            Constants.Analytics.Events.ChatDisplayed.Parameters.otherId: self.contactIds] as? [String: String] {
            Analytics.Log(event: Constants.Analytics.Events.ChatDisplayed.name, with: analyticsEventParameters)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.sendMessageTextView.resignFirstResponder()
        self.label.isHidden = true
        self.label.alpha = 0.0
        self.typingLabel.isHidden = true
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Applozic.NEW_MESSAGE_NOTIFICATION), object: nil)
    }
    
    func newMessage() {
        setNavigationItemTitle()
        scrollTableViewToBottom(withAnimation: true)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let navigationController = navigationController else { return }
        
        if scrollView == sendMessageTextView {
            return
        }
        
        var doneConversation = false
        var doneOtherwise = false
        
        if conversationId != nil && ALApplozicSettings.getContextualChatOption() {
            doneConversation = ALUserDefaultsHandler.isShowLoadEarlierOption(conversationId.stringValue) && ALUserDefaultsHandler.isServerCallDone(forMSGList: conversationId.stringValue)
        } else {
            let ids: String = (self.channelKey != nil) ? self.channelKey.stringValue : self.contactIds
            doneOtherwise = ALUserDefaultsHandler.isShowLoadEarlierOption(ids) && ALUserDefaultsHandler.isServerCallDone(forMSGList: ids)
        }
        
        if scrollView.contentOffset.y == -(UIApplication.shared.statusBarFrame.height + navigationController.navigationBar.frame.height) && (doneConversation || doneOtherwise) {
            self.loadEarlierAction.isHidden = false
        } else {
            self.loadEarlierAction.isHidden = true
        }
    }
    
    func showProfile() {
        if let userDetailsViewController = self.storyboard?.instantiateViewController(withIdentifier: "UserDetailsViewController") as? UserDetailsViewController {
            userDetailsViewController.buttonsType = .options
            let user = User(uid: alContact.userId)
            user.profile.loadFromFirebase { profile, error in
                userDetailsViewController.user = user
                self.present(userDetailsViewController, animated: true, completion: nil)
            }
        }
    }
    
    func keyboardWillShow(_ notification: NSNotification) {
        if let keyboardFrameEnd = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect, let animationDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval {
            self.checkBottomConstraint.constant = self.view.frame.size.height - keyboardFrameEnd.origin.y //+ 5.0
            UIView.animate(withDuration: animationDuration, animations: {
                self.view.layoutIfNeeded()
                self.scrollTableViewToBottom(withAnimation: false)
            }, completion: { finished in
                if finished {
                    self.scrollTableViewToBottom(withAnimation: true)
                }
            })
        }
    }
    
    override func scrollTableViewToBottom(withAnimation animated: Bool) {
        if mTableView.contentSize.height > mTableView.frame.size.height {
            let offset = CGPoint(x: 0, y: mTableView.contentSize.height - mTableView.frame.size.height + typingMessageView.frame.size.height - 7.0)
            mTableView.setContentOffset(offset, animated: animated)
        }
    }
    
    @IBAction func doScroll(_ sender: Any) {
        scrollTableViewToBottom(withAnimation: true)
    }
    
    func keyboardDidHide(_ notification: NSNotification) {
        scrollTableViewToBottom(withAnimation: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let theMessage = self.alMessageWrapper.getUpdatedMessageArray()[indexPath.row] as? ALMessage {
            if (theMessage.fileMeta == nil || (theMessage.fileMeta.thumbnailUrl == nil && theMessage.fileMeta.contentType == nil)) && theMessage.type != "100" {
                return super.tableView(tableView, heightForRowAt: indexPath) - 25.0
            } else {
                return super.tableView(tableView, heightForRowAt: indexPath)
            }
        } else {
            return 0
        }
    }
    
}
