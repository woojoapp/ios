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
            self.rawResponse = rawResponse
            if let dict = rawResponse as? [String:Any] {
                let friends = dict[Constants.GraphRequest.UserFriends.keys.data] as! NSArray
                for friendData in friends {
                    if let friend = Friend.from(graphAPI: friendData as? [String:Any]) {
                        self.friends.append(friend)
                    }
                }
            }
        }
        
        var dictionaryValue: [String : Any]? {
            return rawResponse as? [String : Any]
        }
        var rawResponse: Any?
        var friends: [Friend] = []
        
    }
    
    var graphPath = Constants.GraphRequest.UserFriends.path
    var parameters: [String: Any]? = {
        let fields = [Constants.GraphRequest.UserFriends.fields]
        return [Constants.GraphRequest.fields:fields.joined(separator: Constants.GraphRequest.fieldsSeparator)]
    }()
    var accessToken: AccessToken? = AccessToken.current
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion
    
}
