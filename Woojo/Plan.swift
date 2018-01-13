//
//  Plan.swift
//  Woojo
//
//  Created by Edouard Goossens on 11/01/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import Foundation

class Plan {
    var id: String? {
        get {
            if let id = place.id {
                return "\(id)_on_\(Plan.idDateFormatter.string(from: date))"
            } else {
                return nil
            }
        }
    }
    var place: Place
    var date: Date
    var name: String? {
        get {
            if let name = place.name {
                return "\(name), \(Plan.nameDateFormatter.string(from: date))"
            } else {
                return nil
            }
        }
    }
    
    init(place: Place, date: Date) {
        self.place = place
        self.date = date
    }
    
    static let idDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        //formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = Constants.Plan.dateFormatForId
        return formatter
    }()
    
    static let nameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        //formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = Constants.Plan.dateFormatForName
        return formatter
    }()
    
    static let humanDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        //formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = Constants.Plan.humanDateFormat
        return formatter
    }()
    
    func toEvent() -> Event? {
        if let id = id, let name = name {
            let event = Event(id: id, name: name, start: date) // Name and date will be reset by the backend
            event.place = place
            event.type = "plan"
            return event
        } else {
            return nil
        }
    }
}
