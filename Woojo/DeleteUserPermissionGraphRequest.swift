//
//  DeleteUserPermissionGraphRequest.swift
//  Woojo
//
//  Created by Edouard Goossens on 25/05/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import Foundation
import FacebookCore

struct DeleteUserPermissionGraphRequest: GraphRequestProtocol {
    
    struct Response: GraphResponseProtocol {
        
        init(rawResponse: Any?) {
            if let dict = rawResponse as? [String: Any], let success = dict["success"] as? Bool {
                self.success = success
            } else {
                self.success = false
            }
        }
        
        var success: Bool
        
    }
    
    var parameters: [String : Any]?
    var permission: String
    var graphPath: String {
        get {
            return "me/permissions/\(permission)"
        }
    }
    var accessToken = AccessToken.current
    var httpMethod: GraphRequestHTTPMethod = .DELETE
    var apiVersion: GraphAPIVersion = .defaultVersion
    
    init(permission: String) {
        self.permission = permission
    }
}
