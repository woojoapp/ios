//
//  User.swift
//  Woojo
//
//  Created by Edouard Goossens on 14/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import FirebaseDatabase
import Atlas

class User: NSObject, PublicProfile, ATLParticipant, ATLAvatarItem {
    
    var firstName: String = "User"
    var lastName: String = ""
    var userID: String = "testuser"
    var avatarImageURL: URL?
    var avatarImage: UIImage? {
        get {
            if let profilePhoto = self.profilePhoto {
                return profilePhoto
            } else {
                return nil
            }
        }
    }
    var avatarInitials: String? {
        get {
            return firstName
        }
    }
    var displayName: String {
        get {
            return firstName
        }
    }
    var profilePhoto: UIImage?
    var gender: Gender = .female
    
}

extension User {
    static let firebasePath = "users"
    static let dateFormatter: DateFormatter = {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
        return formatter
    }()
    
    static func from(snapshot: FIRDataSnapshot) -> User? {
        let value = snapshot.value as! [String:Any]
        
        let testUser = User()
        testUser.userID = snapshot.key
        
        guard let account = value["account"] as? [String:Any] else {
            print("Can't create a user without account data.")
            return nil
        }
        
        guard let profile = account["profile"] as? [String:Any] else {
            print("Can't create a user without account profile data.")
            return nil
        }
        
        testUser.avatarImageURL = URL(string: profile["profileImageURL"] as! String)
        
        guard let cachedUserProfile = profile["cachedUserProfile"] as? [String:Any] else {
            print("Can't create a user without account profile cachedUserProfile data.")
            return nil
        }
        
        testUser.firstName = cachedUserProfile["first_name"] as! String
        testUser.lastName = cachedUserProfile["last_name"] as! String
        testUser.gender = Gender(rawValue: cachedUserProfile["gender"] as! String)!
        
        return testUser
    }
    
    static func get(by uid: String, completion: @escaping (User) -> Void) {
        FIRDatabase.database().reference().child(User.firebasePath).child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            if let user = User.from(snapshot: snapshot) {
                completion(user)
            } else {
                print("Failed to get user with uid \(uid)")
            }
        })
    }
    
    func toAny() -> Any {
        let any = [String:Any]()
        
        return any
    }
}
