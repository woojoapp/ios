//
//  UserAlbumsGraphRequest.swift
//  Woojo
//
//  Created by Edouard Goossens on 13/12/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import FacebookCore

struct UserAlbumsGraphRequest: GraphRequestProtocol {
    
    struct Response: GraphResponseProtocol {
        
        init(rawResponse: Any?) {
            if let dict = rawResponse as? [String: Any] {
                albums = try? [GraphAPI.Album](from: dict["data"]) ?? []
            }
        }

        var albums: [GraphAPI.Album]?
    }
    
    var graphPath = "/me/albums"
    var parameters: [String: Any]? = ["fields": "id,name,count,picture.type(small){url}"]
    var accessToken = AccessToken.current
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion
    
}
