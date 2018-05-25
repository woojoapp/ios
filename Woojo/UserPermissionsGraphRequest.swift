//
//  UserPermissionsGraphRequest.swift
//  Woojo
//
//  Created by Edouard Goossens on 25/05/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import Foundation
import FacebookCore

struct UserPermissionsGraphRequest: GraphRequestProtocol {
    
    struct Response: GraphResponseProtocol {
        
        init(rawResponse: Any?) {
            if let dict = rawResponse as? [String:Any] {
                permissions = [GraphAPI.Permission](from: dict["data"]) ?? []
            }
        }
        
        var permissions: [GraphAPI.Permission] = []
        
    }
    
    var graphPath = "/me/permissions"
    var parameters: [String: Any]?
    var accessToken: AccessToken?
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion
    
    init(accessToken: AccessToken) {
        self.accessToken = accessToken
    }
}
