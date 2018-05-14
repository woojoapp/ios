//
//  UserEventGraphRequest.swift
//  Woojo
//
//  Created by Edouard Goossens on 16/11/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import Foundation
import FacebookCore

struct UserEventGraphRequest: GraphRequestProtocol {
    
    struct Response: GraphResponseProtocol {
        
        init(rawResponse: Any?) {
            event = GraphAPI.Event(from: rawResponse)
        }
        
        var event: GraphAPI.Event?
        
    }
    
    var eventId: String
    var graphPath: String {
        get {
            return "/\(eventId)"
        }
    }
    var parameters: [String: Any]? = {
        let fields = ["id",
                      "name",
                      "place",
                      "start_time",
                      "end_time",
                      "picture.type(normal){url}",
                      "cover{source}",
                      "attending_count",
                      "interested_count",
                      "noreply_count",
                      "description",
                      "type"]
        return ["fields": fields.joined(separator: ",")]
    }()
    var accessToken = AccessToken.current
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion
    
    init(eventId: String) {
        self.eventId = eventId
    }
}
