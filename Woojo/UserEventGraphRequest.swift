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
            self.rawResponse = rawResponse
            if let dict = rawResponse as? [String:Any] {
                if let event = Event.from(graphAPI: dict) {
                    self.event = event
                }
            }
        }
        
        var dictionaryValue: [String : Any]? {
            return rawResponse as? [String : Any]
        }
        var rawResponse: Any?
        var event: Event?
        
    }
    
    var eventId: String
    var graphPath: String {
        get {
            return "/\(eventId)"
        }
    }
    var parameters: [String: Any]? = {
        let fields = [Constants.Event.properties.graphAPIKeys.id,
                      Constants.Event.properties.graphAPIKeys.name,
                      Constants.Event.properties.graphAPIKeys.start,
                      Constants.Event.properties.graphAPIKeys.end,
                      Constants.Event.properties.graphAPIKeys.place,
                      Constants.Event.properties.graphAPIKeys.attendingCount,
                      //Constants.Event.properties.graphAPIKeys.rsvpStatus,
                      Constants.GraphRequest.UserEvents.fieldPictureUrl]
        return [Constants.GraphRequest.fields:fields.joined(separator: Constants.GraphRequest.fieldsSeparator)]
    }()
    var accessToken: AccessToken? = AccessToken.current
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion
    
    init(eventId: String) {
        self.eventId = eventId
    }
}
