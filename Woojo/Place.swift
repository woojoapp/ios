//
//  Place.swift
//  Woojo
//
//  Created by Edouard Goossens on 18/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseDatabase

struct Place {
    
    var name: String?
    var location: Location?
    
}

extension Place {
    static func from(firebase snapshot: FIRDataSnapshot) -> Place? {
        if let value = snapshot.value as? [String:Any] {
            var place = Place()
            place.name = value[Constants.Event.Place.properties.firebaseNodes.name] as? String
            place.location = Location.from(firebase: snapshot.childSnapshot(forPath: Constants.Event.Place.properties.firebaseNodes.location))
            return place
        } else {
            return nil
        }
    }
    
    static func from(graphAPI dict: [String:Any]?) -> Place? {
        if let dict = dict {
            var place = Place()
            place.name = dict[Constants.Event.Place.properties.graphAPIKeys.name] as? String
            place.location = Location.from(graphAPI: dict[Constants.Event.Place.properties.graphAPIKeys.location] as? [String:Any])
            return place
        } else {
            return nil
        }
    }
    
    func toDictionary() -> [String:Any] {
        var dict: [String:Any] = [:]
        dict[Constants.Event.Place.properties.firebaseNodes.name] = self.name
        dict[Constants.Event.Place.properties.firebaseNodes.location] = self.location?.toDictionary()
        return dict
    }
}
