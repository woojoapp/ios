//
//  Event.swift
//  Woojo
//
//  Created by Edouard Goossens on 03/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseDatabase

struct Event {
    
    let id: String
    let name: String
    let start: Date
    let end: Date?
    let place: [String:Any]?
    let picture: [String:Any]
    var pictureData: Data? {
        get {
            let data = picture["data"] as! [String:Any]
            return Data(base64Encoded: data["base64"] as! String, options: .ignoreUnknownCharacters)
        }
    }
    
    /*init(id: String, name: String, start: Date, place: [String:Any], picture: [String:Any]) {
        self.id = id
        self.name = name
        self.start = start
        self.place = place
        self.picture = picture
    }*/
    
}

extension Event {
    static var firebasePath = "events"
    static let dateFormatter: DateFormatter = {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
        return formatter
    }()
    
    static func from(snapshot: FIRDataSnapshot) -> Event? {
        let value = snapshot.value as! [String:Any]
        var endTime: Date?
        if let end = value["end_time"] as? String {
            endTime = Event.dateFormatter.date(from: end)
        }
        let place = value["place"] as! [String : Any]?
        if let id = value["id"] as? String,
            let name = value["name"] as? String,
            let start = value["start_time"] as? String,
            let picture = value["picture"] as? [String:Any] {
            return Event(id: id, name: name, start: Event.dateFormatter.date(from: start)!, end: endTime, place: place, picture: picture)
        }
        return nil
    }
    
    func toAny() -> Any {
        var any = [
            "id": self.id,
            "name": self.name,
            "start_time": Event.dateFormatter.string(from: self.start),
        ]
        
        if let end = self.end {
            any["end"] = Event.dateFormatter.string(from: end)
        }
        
        return any
    }
}
