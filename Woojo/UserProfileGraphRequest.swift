//
//  UserProfileGraphRequest.swift
//  Woojo
//
//  Created by Edouard Goossens on 16/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import FacebookCore
import FirebaseAuth

struct UserProfileGraphRequest: GraphRequestProtocol {
    
    struct Response: GraphResponseProtocol {
        
        init(rawResponse: Any?) {
            self.rawResponse = rawResponse
            if let rawResponse = rawResponse as? [String:Any] {
                profile = Profile.from(graphAPI: rawResponse)
                fbAppScopedID = rawResponse["id"] as? String
            }
        }
        
        var rawResponse: Any?
        var profile: Profile?
        var fbAppScopedID: String?
        
    }
    
    var graphPath = Constants.GraphRequest.UserProfile.path
    var parameters: [String: Any]? = {
        let fields = [Constants.GraphRequest.UserProfile.fieldID,
                      Constants.User.Profile.properties.graphAPIKeys.firstName,
                      Constants.User.Profile.properties.graphAPIKeys.ageRange,
                      Constants.User.Profile.properties.graphAPIKeys.gender]
        return [Constants.GraphRequest.fields:fields.joined(separator: Constants.GraphRequest.fieldsSeparator)]
    }()
    var accessToken: AccessToken? = AccessToken.current
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion
    
}
