//
//  EventbriteEvent.swift
//  Woojo
//
//  Created by Edouard Goossens on 23/02/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import Foundation

class EventbriteEvent: Codable {
    var id: String
    var name: TextField
    var description: TextField
    var start: TimeField
    var end: TimeField
    var capacity: Int
    var venue: Venue
    var logo: Logo
    
    func toEvent() -> Event {
        let event = Event(id: "eventbrite_\(id)", name: name.text, start: Event.dateFormatter.date(from: start.local)!)
        event.description = description.text
        event.place = venue.toPlace()
        event.pictureURL = URL(string: logo.url)
        event.coverURL = URL(string: logo.original.url)
        event.rsvpStatus = Event.RSVP.attending.rawValue
        event.end = Event.dateFormatter.date(from: end.local)
        event.attendingCount = capacity
        return event
    }
    
    class TextField: Codable {
        var text: String
        var html: String
    }
    
    class TimeField: Codable {
        var timezone: String
        var local: String
        var utc: String
    }
    
    class Logo: Codable {
        var url: String
        var original: Original
        
        class Original: Codable {
            var url: String
        }
    }
    
    class Venue: Codable {
        var id: String
        var name: String?
        var address: Address
        
        func toPlace() -> Place {
            var place = Place()
            place.id = id
            place.name = name
            place.location = address.toLocation()
            return place
        }
        
        class Address: Codable {
            var address1: String?
            var address2: String?
            var city: String?
            var postalCode: String?
            var country: String?
            var latitude: String
            var longitude: String
            
            enum CodingKeys: String, CodingKey {
                case address1 = "address_1"
                case address2 = "address_2"
                case postalCode = "postal_code"
                case city, country, latitude, longitude
            }
            
            func toLocation() -> Location {
                var location = Location()
                location.street = "\(address1 ?? "") \(address2 ?? "")"
                location.city = city
                location.zip = postalCode
                location.country = country
                location.longitude = Float(longitude)
                location.latitude = Float(latitude)
                return location
            }
        }
    }
}
