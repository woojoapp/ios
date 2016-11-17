//
//  UserProfileGraphRequest.swift
//  Woojo
//
//  Created by Edouard Goossens on 16/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import FacebookCore

struct UserProfileGraphRequest: GraphRequestProtocol {
    
    struct Response: GraphResponseProtocol {
        
        init(rawResponse: Any?) {
            self.rawResponse = rawResponse
            if let rawResponse = rawResponse as? [String:Any] {
                self.firstName = rawResponse["first_name"] as? String
                if let gender = rawResponse["gender"] as? String {
                    self.gender = Gender(rawValue: gender)
                }
                if let ageRange = rawResponse["age_range"] as? [String:Any] {
                    self.ageRange = (ageRange["min"] as? Int, ageRange["max"] as? Int)
                }
            }
        }
        
        var dictionaryValue: [String : Any]? {
            return rawResponse as? [String : Any]
        }
        var rawResponse: Any?
        var firstName: String?
        var gender: Gender?
        var ageRange: (min: Int?, max: Int?)
        
    }
    
    var graphPath = "/me"
    var parameters: [String: Any]? = ["fields": "id, first_name, age_range, birthday, gender"]
    var accessToken: AccessToken? = AccessToken.current
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion
    
}
