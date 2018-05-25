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
}
