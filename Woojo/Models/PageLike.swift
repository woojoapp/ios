//
//  PageLike.swift
//  Woojo
//
//  Created by Edouard Goossens on 07/11/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseDatabase

class PageLike: CommonItem, Codable {
    var id: String?
    var name: String?
    var pictureURL: URL?
    
    private enum CodingKeys: String, CodingKey {
        case id, name
        case pictureURL = "picture_url"
    }
    
    /* static func from(graphAPI dict: [String:Any]?) -> PageLike? {
        if let dict = dict,
            let id = dict[Constants.User.PageLike.properties.graphAPIKeys.id] as? String,
            let name = dict[Constants.User.PageLike.properties.graphAPIKeys.name] as? String {
            let pageLike = PageLike(id: id)
            if let picture = dict[Constants.User.PageLike.properties.graphAPIKeys.picture] as? [String:Any] {
                if let pictureData = picture[Constants.User.PageLike.properties.graphAPIKeys.pictureData] as? [String:Any] {
                    if let url = pictureData[Constants.User.PageLike.properties.graphAPIKeys.pictureDataURL] as? String {
                        pageLike.pictureURL = URL(string: url)
                    }
                }
            }
            pageLike.name = name
            return pageLike
        } else {
            print("Failed to create PageLike from Graph API dictionary. Nil or missing required data.", dict as Any)
            return nil
        }
    }
    
    static func from(firebase snapshot: DataSnapshot) -> PageLike {
        let pageLike = PageLike(id: snapshot.key)
        pageLike.name = snapshot.childSnapshot(forPath: Constants.User.PageLike.properties.firebaseNodes.name).value as? String
        if let url = snapshot.childSnapshot(forPath: Constants.User.PageLike.properties.firebaseNodes.pictureURL).value as? String {
            pageLike.pictureURL = URL(string: url)
        }
        return pageLike
    }
    
    func toDictionary() -> [String:Any] {
        var dict: [String:Any] = [:]
        dict[Constants.User.PageLike.properties.firebaseNodes.id] = self.id
        dict[Constants.User.PageLike.properties.firebaseNodes.name] = self.name
        dict[Constants.User.PageLike.properties.firebaseNodes.pictureURL] = self.pictureURL?.absoluteString
        return dict
    } */
}

