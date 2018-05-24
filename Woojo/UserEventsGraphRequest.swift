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
            if let dict = rawResponse as? [String:Any] {
                print("LOGGIN RAW", dict)
                events = [GraphAPI.Event](from: dict["data"])
            }
        }
    
        var events: [GraphAPI.Event]?
        
    }
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()
    
    var type: String?
    var graphPath = "/me/events"
    var parameters: [String: Any]? {
        get {
            var parameters = [String: String]()
            let fields = ["id",
                          "name",
                          "place",
                          "start_time",
                          "end_time",
                          "cover{source}",
                          "attending_count",
                          "interested_count",
                          "noreply_count",
                          "description",
                          "rsvp_status",
                          "type"]
            parameters["fields"] = fields.joined(separator: ",")
            if let type = type {
                parameters["type"] = type
            }
            parameters["since"] = UserEventsGraphRequest.dateFormatter.string(from: Calendar.current.date(byAdding: .month, value: -1, to: Date())!)
            return parameters
        }
    }
    var accessToken = AccessToken.current
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion
    
    init(type: String? = nil) {
        self.type = type
    }
}

