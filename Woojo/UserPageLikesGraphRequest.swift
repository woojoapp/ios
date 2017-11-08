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
            self.rawResponse = rawResponse
            if let dict = rawResponse as? [String:Any] {
                let pageLikes = dict[Constants.GraphRequest.UserPageLikes.keys.data] as! NSArray
                for pageLikeData in pageLikes {
                    if let pageLike = PageLike.from(graphAPI: pageLikeData as? [String:Any]) {
                        self.pageLikes.append(pageLike)
                    }
                }
            }
        }
        
        var dictionaryValue: [String : Any]? {
            return rawResponse as? [String : Any]
        }
        var rawResponse: Any?
        var pageLikes: [PageLike] = []
        
    }
    
    var graphPath = Constants.GraphRequest.UserPageLikes.path
    var parameters: [String: Any]? = {
        let fields = [Constants.GraphRequest.UserPageLikes.fields]
        return [Constants.GraphRequest.fields:fields.joined(separator: Constants.GraphRequest.fieldsSeparator)]
    }()
    var accessToken: AccessToken? = AccessToken.current
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion
    
}


