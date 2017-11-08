//
//  Friend.swift
//  Woojo
//
//  Created by Edouard Goossens on 07/11/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseDatabase

class Friend: CommonItem {
    var id: String
    var name: String?
    var pictureURL: URL?
    
    init(id: String) {
        self.id = id
    }
    
    static func from(graphAPI dict: [String:Any]?) -> Friend? {
        if let dict = dict,
            let id = dict[Constants.User.Friend.properties.graphAPIKeys.id] as? String,
            let name = dict[Constants.User.Friend.properties.graphAPIKeys.name] as? String {
            let friend = Friend(id: id)
            if let picture = dict[Constants.User.Friend.properties.graphAPIKeys.picture] as? [String:Any] {
                if let pictureData = picture[Constants.User.Friend.properties.graphAPIKeys.pictureData] as? [String:Any] {
                    if let url = pictureData[Constants.User.Friend.properties.graphAPIKeys.pictureDataURL] as? String {
                        friend.pictureURL = URL(string: url)
                    }
                }
            }
            friend.name = name
            return friend
        } else {
            print("Failed to create Friend from Graph API dictionary. Nil or missing required data.", dict as Any)
            return nil
        }
    }
    
    static func from(firebase snapshot: DataSnapshot) -> Friend {
        let friend = Friend(id: snapshot.key)
        friend.name = snapshot.childSnapshot(forPath: Constants.User.Friend.properties.firebaseNodes.name).value as? String
        if let url = snapshot.childSnapshot(forPath: Constants.User.Friend.properties.firebaseNodes.pictureURL).value as? String {
            friend.pictureURL = URL(string: url)
        }
        return friend
    }
    
    func toDictionary() -> [String:Any] {
        var dict: [String:Any] = [:]
        dict[Constants.User.Friend.properties.firebaseNodes.id] = self.id
        dict[Constants.User.Friend.properties.firebaseNodes.name] = self.name
        dict[Constants.User.Friend.properties.firebaseNodes.pictureURL] = self.pictureURL?.absoluteString
        return dict
    }
}
