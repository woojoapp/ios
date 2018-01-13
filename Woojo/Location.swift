//
//  Location.swift
//  Woojo
//
//  Created by Edouard Goossens on 18/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseDatabase
import Contacts

struct Location {
    
    var country: String?
    var city: String?
    var zip: String?
    var street: String?
    var latitude: Float?
    var longitude: Float?
    var name: String?
    var addressString: String {
        get {
            let address = CNMutablePostalAddress()
            if let city = city {
                address.city = city
            }
            if let zip = zip {
                address.postalCode = zip
            }
            if let country = country {
                address.country = country
            }
            if let street = street {
                address.street = street
            }
            /*var addressString = ""
            if let country = country {
                addressString = country
            }
            if let city = city {
                if addressString != "" {
                    addressString = "\(city) (\(addressString))"
                }
            }
            if let street = street {
                if addressString != "" {
                    addressString = "\(street)\n\(addressString)"
                }
            }*/
            return CNPostalAddressFormatter.string(from: address, style: .mailingAddress)
        }
    }
}

extension Location {
    static func from(firebase snapshot: DataSnapshot) -> Location? {
        if let value = snapshot.value as? [String:Any] {
            var location = Location()
            location.country = value[Constants.Place.Location.properties.firebaseNodes.country] as? String
            location.city = value[Constants.Place.Location.properties.firebaseNodes.city] as? String
            location.zip = value[Constants.Place.Location.properties.firebaseNodes.zip] as? String
            location.street = value[Constants.Place.Location.properties.firebaseNodes.street] as? String
            location.latitude = value[Constants.Place.Location.properties.firebaseNodes.latitude] as? Float
            location.longitude = value[Constants.Place.Location.properties.firebaseNodes.longitude] as? Float
            return location
        } else {
            return nil
        }
    }
    
    static func from(graphAPI dict: [String:Any]?) -> Location? {
        if let dict = dict {
            var location = Location()
            location.country = dict[Constants.Place.Location.properties.graphAPIKeys.country] as? String
            location.city = dict[Constants.Place.Location.properties.graphAPIKeys.city] as? String
            location.zip = dict[Constants.Place.Location.properties.graphAPIKeys.zip] as? String
            location.street = dict[Constants.Place.Location.properties.graphAPIKeys.street] as? String
            location.latitude = dict[Constants.Place.Location.properties.graphAPIKeys.latitude] as? Float
            location.longitude = dict[Constants.Place.Location.properties.graphAPIKeys.longitude] as? Float
            location.name = dict[Constants.Place.Location.properties.graphAPIKeys.name] as? String
            return location
        } else {
            return nil
        }
    }
    
    func toDictionary() -> [String:Any] {
        var dict: [String:Any] = [:]
        dict[Constants.Place.Location.properties.firebaseNodes.name] = self.name
        dict[Constants.Place.Location.properties.firebaseNodes.country] = self.country
        dict[Constants.Place.Location.properties.firebaseNodes.city] = self.city
        dict[Constants.Place.Location.properties.firebaseNodes.zip] = self.zip
        dict[Constants.Place.Location.properties.firebaseNodes.street] = self.street
        dict[Constants.Place.Location.properties.firebaseNodes.latitude] = self.latitude
        dict[Constants.Place.Location.properties.firebaseNodes.longitude] = self.longitude
        return dict
    }
}
