//
//  ChatViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 15/02/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import Applozic
import SDWebImage
import NotificationCenter

class ChatViewController: ALChatViewController {
    
    @IBOutlet weak var loadEarlierAction: UIButton!
    
    let translucentColor = UIColor(red: 247.0/255.0, green: 247.0/255.0, blue: 247.0/255.0, alpha: 0.95)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.placeHolderTxt = "Write a message..."
        ALApplozicSettings.setColorForSendMessages(self.view.tintColor)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.layer.shadowOpacity = 0.0
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
        
        profileButton.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        
        navigationItem.setRightBarButton(profileItem, animated: true)
        let button = navigationItem.titleView as! UIButton
        if let title = button.title(for: .normal) {
            let titleString = NSAttributedString(string: title, attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17.0)])
            button.setAttributedTitle(titleString, for: .normal)
        }
        
        label.textColor = label.textColor.withAlphaComponent(0.6)
        
        mTableView.backgroundColor = UIColor.white
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        //NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loadEarlierAction.backgroundColor = translucentColor
        let titleString = NSAttributedString(string: "Load earlier messages", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 12.0), NSForegroundColorAttributeName: self.view.tintColor])
        loadEarlierAction.setAttributedTitle(titleString, for: .normal)
        let bottomBorder = UIView(frame: CGRect(x: 0, y: loadEarlierAction.frame.height - 4, width: loadEarlierAction.frame.width, height: 1))
        bottomBorder.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        loadEarlierAction.addSubview(bottomBorder)
    }
    
    func tapped() {
        print("Tapped", self.alContact.userId)
    }
    
    func keyboardWillShow(_ notification: NSNotification) {
        if let keyboardFrameEnd = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect, let animationDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval {
            self.checkBottomConstraint.constant = self.view.frame.size.height - keyboardFrameEnd.origin.y + 0
            UIView.animate(withDuration: animationDuration, animations: {
                self.view.layoutIfNeeded()
                self.scrollTableViewToBottom(withAnimation: true)
            }, completion: { finished in
                if finished {
                    self.scrollTableViewToBottom(withAnimation: true)
                }
            })
        }
    }
    
    override func scrollTableViewToBottom(withAnimation animated: Bool) {
        if mTableView.contentSize.height > mTableView.frame.size.height {
            let offset = CGPoint(x: 0, y: mTableView.contentSize.height - mTableView.frame.size.height + 53.0)
            mTableView.setContentOffset(offset, animated: animated)
        }
    }
    
    func keyboardDidHide(_ notification: NSNotification) {
        scrollTableViewToBottom(withAnimation: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let theMessage = self.alMessageWrapper.getUpdatedMessageArray()[indexPath.row] as? ALMessage {
            if (theMessage.fileMeta == nil || (theMessage.fileMeta.thumbnailUrl == nil && theMessage.fileMeta.contentType == nil)) && theMessage.type != "100" {
                return super.tableView(tableView, heightForRowAt: indexPath) - 20.0
            } else {
                return super.tableView(tableView, heightForRowAt: indexPath)
            }
        } else {
            return 0
        }
    }
    
}
