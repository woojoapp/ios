//
//  Location.swift
//  Woojo
//
//  Created by Edouard Goossens on 18/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseDatabase

struct Location {
    
    var country: String?
    var city: String?
    var zip: String?
    var street: String?
    var latitude: Float?
    var longitude: Float?
    var name: String?
    
}

extension Location {
    static func from(firebase snapshot: FIRDataSnapshot) -> Location? {
        if let value = snapshot.value as? [String:Any] {
            var location = Location()
            location.country = value[Constants.Event.Place.Location.properties.firebaseNodes.country] as? String
            location.city = value[Constants.Event.Place.Location.properties.firebaseNodes.city] as? String
            location.zip = value[Constants.Event.Place.Location.properties.firebaseNodes.zip] as? String
            location.street = value[Constants.Event.Place.Location.properties.firebaseNodes.street] as? String
            location.latitude = value[Constants.Event.Place.Location.properties.firebaseNodes.latitude] as? Float
            location.longitude = value[Constants.Event.Place.Location.properties.firebaseNodes.longitude] as? Float
            return location
        } else {
            return nil
        }
    }
    
    static func from(graphAPI dict: [String:Any]?) -> Location? {
        if let dict = dict {
            var location = Location()
            location.country = dict[Constants.Event.Place.Location.properties.graphAPIKeys.country] as? String
            location.city = dict[Constants.Event.Place.Location.properties.graphAPIKeys.city] as? String
            location.zip = dict[Constants.Event.Place.Location.properties.graphAPIKeys.zip] as? String
            location.street = dict[Constants.Event.Place.Location.properties.graphAPIKeys.street] as? String
            location.latitude = dict[Constants.Event.Place.Location.properties.graphAPIKeys.latitude] as? Float
            location.longitude = dict[Constants.Event.Place.Location.properties.graphAPIKeys.longitude] as? Float
            location.name = dict[Constants.Event.Place.Location.properties.graphAPIKeys.name] as? String
            return location
        } else {
            return nil
        }
    }
    
    func toDictionary() -> [String:Any] {
        var dict: [String:Any] = [:]
        dict[Constants.Event.Place.Location.properties.firebaseNodes.name] = self.name
        dict[Constants.Event.Place.Location.properties.firebaseNodes.country] = self.country
        dict[Constants.Event.Place.Location.properties.firebaseNodes.city] = self.city
        dict[Constants.Event.Place.Location.properties.firebaseNodes.zip] = self.zip
        dict[Constants.Event.Place.Location.properties.firebaseNodes.street] = self.street
        dict[Constants.Event.Place.Location.properties.firebaseNodes.latitude] = self.latitude
        dict[Constants.Event.Place.Location.properties.firebaseNodes.longitude] = self.longitude
        return dict
    }
}
