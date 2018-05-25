//
//  EventbriteEvent.swift
//  Woojo
//
//  Created by Edouard Goossens on 23/02/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import Foundation

extension EventbriteAPI {
    class Event: Codable {
        var id: String
        var name: TextField
        var description: TextField
        var start: TimeField
        var end: TimeField
        var capacity: Int
        var venue: Venue
        var logo: Logo
        
        func toEvent() -> Woojo.Event {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            let event = Woojo.Event()
            event.id = "eventbrite_\(id)"
            event.name = name.text
            event.start = formatter.date(from: start.local)
            event.description = description.text
            event.place = venue.toPlace()
            event.coverURL = logo.original.url
            event.rsvpStatus = Woojo.Event.RSVP.attending.rawValue
            event.end = formatter.date(from: end.local)
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
}
