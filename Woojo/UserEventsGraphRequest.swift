//
//  UserEventsGraphRequest.swift
//  Woojo
//
//  Created by Edouard Goossens on 18/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import FacebookCore

struct UserEventsGraphRequest: GraphRequestProtocol {
    
    struct Response: GraphResponseProtocol {
        
        init(rawResponse: Any?) {
            self.rawResponse = rawResponse
            if let dict = rawResponse as? [String:Any] {
                let events = dict[Constants.GraphRequest.UserEvents.keys.data] as! NSArray
                for eventData in events {
                    if let event = Event.from(graphAPI: eventData as? [String:Any]) {
                        self.events.append(event)
                    }
                }
            }
        }
        
        var dictionaryValue: [String : Any]? {
            return rawResponse as? [String : Any]
        }
        var rawResponse: Any?
        var events: [Event] = []
        
    }
    
    var graphPath = Constants.GraphRequest.UserEvents.path
    var parameters: [String: Any]? = {
        let fields = [Constants.Event.properties.graphAPIKeys.id,
                      Constants.Event.properties.graphAPIKeys.name,
                      Constants.Event.properties.graphAPIKeys.start,
                      Constants.Event.properties.graphAPIKeys.end,
                      Constants.Event.properties.graphAPIKeys.place,
                      Constants.Event.properties.graphAPIKeys.attendingCount,
                      Constants.GraphRequest.UserEvents.fieldPictureUrl]
        return [Constants.GraphRequest.fields:fields.joined(separator: Constants.GraphRequest.fieldsSeparator),
                "since": Event.dateFormatter.string(from: Calendar.current.date(byAdding: .month, value: -1, to: Date())!)]
    }()
    var accessToken: AccessToken? = AccessToken.current
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion
    
}

