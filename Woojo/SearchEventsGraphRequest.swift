//
//  SearchEventsGraphRequest.swift
//  Woojo
//
//  Created by Edouard Goossens on 28/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import FacebookCore

struct SearchEventsGraphRequest: GraphRequestProtocol {
    
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
    
    init(query: String) {
        self.query = query
    }
    
    var query: String
    var graphPath: String {
        get {
            return "/search?q=\(query)&type=event&fields=name,start_time,attending_count,end_time,rsvp_status,place,picture.type(normal)&since="
        }
    }
    /*var parameters: [String: Any]? = {
        let fields = [Constants.Event.properties.graphAPIKeys.id,
                      Constants.Event.properties.graphAPIKeys.name,
                      Constants.Event.properties.graphAPIKeys.start,
                      Constants.Event.properties.graphAPIKeys.end,
                      Constants.Event.properties.graphAPIKeys.place,
                      Constants.GraphRequest.UserEvents.fieldPictureUrl]
        return [Constants.GraphRequest.fields:fields.joined(separator: Constants.GraphRequest.fieldsSeparator)]
    }()*/
    var parameters: [String:Any]? =  {
        return ["type":"event", "fields":"name,start_time,attending_count,end_time,rsvp_status,place,picture.type(normal)"]
    }()
    var accessToken: AccessToken? = AccessToken.current
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion
    
}
