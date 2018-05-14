//
//  UserPageLikesGraphRequest.swift
//  Woojo
//
//  Created by Edouard Goossens on 04/11/2016.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import Foundation
import FacebookCore

struct UserPageLikesGraphRequest: GraphRequestProtocol {
    
    struct Response: GraphResponseProtocol {
        
        init(rawResponse: Any?) {
            if let dict = rawResponse as? [String: Any] {
                pageLikes = try? [GraphAPI.PageLike](from: dict["data"]) ?? []
            }
        }
        
        var pageLikes: [GraphAPI.PageLike]?
        
    }
    
    var graphPath = "/me/likes"
    var parameters: [String: Any]? = {
        return ["fields": "id,name,picture.type(normal){url}"]
    }()
    var accessToken: AccessToken? = AccessToken.current
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion
    
    /* private static func deserialize(dict: [String:Any]?) -> PageLike? {
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
    } */
}


