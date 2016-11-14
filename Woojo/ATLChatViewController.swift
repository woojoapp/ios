//
//  ChatViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 06/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import LayerKit
import Atlas

class ATLChatViewController: ATLConversationViewController, ATLConversationViewControllerDataSource, ATLConversationViewControllerDelegate {
    
    var dateFormatter: DateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        self.delegate = self
        // Uncomment the following line if you want to show avatars in 1:1 conversations
        // self.shouldDisplayAvatarItemForOneOtherParticipant = true
        
        // Setup the dateformatter used by the dataSource.
        self.dateFormatter.dateStyle = .short
        self.dateFormatter.timeStyle = .short
        
        self.configureUI()
    }
    
    // MARK - UI Configuration methods
    
    func configureUI() {
        ATLOutgoingMessageCollectionViewCell.appearance().messageTextColor = .red
    }
    
    // MARK - ATLConversationViewControllerDelegate methods
    
    func conversationViewController(_ viewController: ATLConversationViewController, didSend message: LYRMessage) {
        print("Message sent!")
    }
    
    func conversationViewController(_ viewController: ATLConversationViewController, didFailSending message: LYRMessage, error: Error) {
        print("Message failed to sent with error: \(error)")
    }
    
    func conversationViewController(_ viewController: ATLConversationViewController, didSelect message: LYRMessage) {
        print("Message selected")
    }
    
    // MARK - ATLConversationViewControllerDataSource methods
    
    func conversationViewController(_ conversationViewController: ATLConversationViewController, participantFor identity: LYRIdentity) -> ATLParticipant {
        return "Doudou" as! ATLParticipant
    }
    
    func conversationViewController(_ conversationViewController: ATLConversationViewController, attributedStringForDisplayOf date: Date) -> NSAttributedString {
        let attributes: NSDictionary = [ NSFontAttributeName : UIFont.systemFont(ofSize: 14), NSForegroundColorAttributeName : UIColor.gray ]
        return NSAttributedString(string: self.dateFormatter.string(from: date as Date), attributes: attributes as? [String : AnyObject])
    }
    
    func conversationViewController(_ conversationViewController: ATLConversationViewController, attributedStringForDisplayOfRecipientStatus recipientStatus: [AnyHashable : Any]) -> NSAttributedString {
        let checkmark: String = "✔︎"
        let textColor: UIColor = UIColor.lightGray
        let statusString: NSAttributedString = NSAttributedString(string: checkmark, attributes: [NSForegroundColorAttributeName: textColor])
        return statusString
    }

    
}
