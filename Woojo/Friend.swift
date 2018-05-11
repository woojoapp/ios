//
//  Friend.swift
//  Woojo
//
//  Created by Edouard Goossens on 07/11/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseDatabase

class Friend: CommonItem, Codable {
    var id: String?
    var name: String?
    var pictureURL: URL?

    private enum CodingKeys: String, CodingKey {
        case id, name
        case pictureURL = "picture_url"
    }
    
    /* static func from(firebase snapshot: DataSnapshot) -> Friend {
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
    } */
}
