//
//  UserFriendsGraphRequest.swift
//  Woojo
//
//  Created by Edouard Goossens on 07/11/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import Foundation
import FacebookCore

struct UserFriendsGraphRequest: GraphRequestProtocol {
    
    struct Response: GraphResponseProtocol {
        
        init(rawResponse: Any?) {
            if let dict = rawResponse as? [String:Any] {
                friends = [GraphAPI.Friend](from: dict["data"])
            }
        }
        
        var friends: [GraphAPI.Friend]?
        
    }
    
    var graphPath = "/me/friends"
    var parameters: [String: Any]? = {
        return ["fields": "id,first_name,picture.type(normal){url}"]
    }()
    var accessToken: AccessToken? = AccessToken.current
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion
    
    /* private static func deserialize(dict: [String:Any]?) -> Friend? {
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
    } */
    
}
