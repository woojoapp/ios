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
    
    var id: String?
    var name: String?
    var start: Date?
    var end: Date?
    var place: Place?
    var pictureURL: URL?
    var description: String?
    
}

extension Event {
    static let dateFormatter: DateFormatter = {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = Constants.Event.dateFormat
        return formatter
    }()
    
    static func from(firebase snapshot: FIRDataSnapshot) -> Event? {
        if let value = snapshot.value as? [String:Any] {
            var event = Event()
            event.id = value[Constants.Event.properties.firebaseNodes.id] as? String
            event.name = value[Constants.Event.properties.firebaseNodes.name] as? String
            event.description = value[Constants.Event.properties.firebaseNodes.description] as? String
            if let pictureURLString = value[Constants.Event.properties.firebaseNodes.pictureURL] as? String {
                event.pictureURL = URL(string: pictureURLString)
            }
            if let startTimeString = value[Constants.Event.properties.firebaseNodes.start] as? String {
                event.start = Event.dateFormatter.date(from: startTimeString)
            }
            if let endTimeString = value[Constants.Event.properties.firebaseNodes.end] as? String {
                event.end = Event.dateFormatter.date(from: endTimeString)
            }
            event.place = Place.from(firebase: snapshot.childSnapshot(forPath: Constants.Event.Place.firebaseNode))
            return event
        } else {
            print("Failed to create Event from Firebase snapshot.", snapshot)
            return nil
        }
    }
    
    static func from(graphAPI dict: [String:Any]?) -> Event? {
        if let dict = dict {
            var event = Event()
            event.id = dict[Constants.Event.properties.graphAPIKeys.id] as? String
            event.name = dict[Constants.Event.properties.graphAPIKeys.name] as? String
            event.description = dict[Constants.Event.properties.graphAPIKeys.description] as? String
            if let startTimeString = dict[Constants.Event.properties.graphAPIKeys.start] as? String {
                event.start = Event.dateFormatter.date(from: startTimeString)
            }
            if let endTimeString = dict[Constants.Event.properties.graphAPIKeys.end] as? String {
                event.end = Event.dateFormatter.date(from: endTimeString)
            }
            if let picture = dict[Constants.Event.properties.graphAPIKeys.picture] as? [String:Any] {
                if let pictureData = picture[Constants.Event.properties.graphAPIKeys.pictureData] as? [String:Any] {
                    if let url = pictureData[Constants.Event.properties.graphAPIKeys.pictureDataURL] as? String {
                        event.pictureURL = URL(string: url)
                    }
                }
            }
            event.place = Place.from(graphAPI: dict[Constants.Event.Place.graphAPIKey] as? [String:Any])
            return event
        } else {
            print("Failed to create Event from Graph API dictionary.", dict as Any)
            return nil
        }

    }
    
    static func get(for id: String, completion: @escaping (Event?) -> Void) {
        FIRDatabase.database().reference().child(Constants.Event.firebaseNode).child(id).observeSingleEvent(of: .value, with: { snapshot in
            completion(from(firebase: snapshot))
        })
    }

}
