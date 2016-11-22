//
//  ChatParticipant.swift
//  Woojo
//
//  Created by Edouard Goossens on 14/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import Atlas

class ChatParticipant: NSObject, ATLParticipant, ATLAvatarItem {
    
    var firstName: String = "User"
    var lastName: String = ""
    var userID: String = "testuser"
    var avatarImageURL: URL?
    var avatarImage: UIImage?
    var avatarInitials: String? {
        get {
            return String(firstName[firstName.startIndex])
        }
    }
    var displayName: String {
        get {
            return firstName
        }
    }
    
}
