//
//  SearchPlacesGraphRequest.swift
//  Woojo
//
//  Created by Edouard Goossens on 11/01/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import Foundation
import FacebookCore

struct SearchPlacesGraphRequest: GraphRequestProtocol {
    
    struct Response: GraphResponseProtocol {
        
        init(rawResponse: Any?) {
            self.rawResponse = rawResponse
            if let dict = rawResponse as? [String:Any] {
                let places = dict["data"] as! NSArray
                for placeData in places {
                    if let place = Place.from(graphAPI: placeData as? [String:Any]) {
                        self.places.append(place)
                    }
                }
            }
        }
        
        var dictionaryValue: [String : Any]? {
            return rawResponse as? [String : Any]
        }
        var rawResponse: Any?
        var places: [Place] = []
        
    }
    
    init(query: String) {
        self.query = query
    }
    
    var query: String
    var graphPath = "/search"
    var parameters: [String:Any]? {
        get {
            return ["q": query,
                    "type": "place",
                    "fields": "id,name,picture.width(200).height(200),location,cover,verification_status"]
        }
    }
    var accessToken: AccessToken? = AccessToken.current
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion
    
}
