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

struct Location: Codable {
    var id: String?
    var name: String?
    var country: String?
    var city: String?
    var zip: String?
    var street: String?
    var latitude: Float?
    var longitude: Float?
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
            return CNPostalAddressFormatter.string(from: address, style: .mailingAddress)
        }
    }
}