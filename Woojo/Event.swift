//
//  Event.swift
//  Woojo
//
//  Created by Edouard Goossens on 03/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseDatabase
import RxSwift
import RxCocoa

class Event {
    
    var id: String
    var name: String
    var start: Date
    var end: Date?
    var place: Place?
    var pictureURL: URL?
    var coverURL: URL?
    var description: String?
    var attendingCount: Int?
    var interestedCount: Int?
    var noReplyCount: Int?
    var rsvpStatus: String = "unsure"
    var type: String?
    var matches: [User] = []
    
    var ref: DatabaseReference {
        get {
            return Database.database().reference().child(Constants.Event.firebaseNode).child(id)
        }
    }
    
    var timesString: String {
        get {
            if type != "plan" {
                var timesString = Event.humanDateFormatter.string(from: start)
                if let end = end {
                    timesString = "\(timesString) - \(Event.humanDateFormatter.string(from: end))"
                }
                return timesString
            } else {
                return Plan.humanDateFormatter.string(from: start)
            }
        }
    }
    
    var rsvpString: String {
        get {
            var rsvpInfo: [String] = []
            if let attendingCount = attendingCount {
                rsvpInfo.append("\(String(attendingCount)) going")
            }
            if let interestedCount = interestedCount {
                rsvpInfo.append("\(String(interestedCount)) maybe")
            }
            if let noReplyCount = noReplyCount {
                rsvpInfo.append("\(String(noReplyCount)) invited")
            }
            return rsvpInfo.joined(separator: ", ")
        }
    }
    
    init(id: String, name: String, start: Date) {
        self.id = id
        self.name = name
        self.start = start
    }
    
}

extension Event {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        //formatter.locale = Locale(identifier: "en_US_POSIX")
        //formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = Constants.Event.dateFormat
        return formatter
    }()
    
    static let humanDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        //formatter.locale = Locale(identifier: "en_US_POSIX")
        //formatter.timeZone = NSTimeZone.local
        formatter.dateFormat = Constants.Event.humanDateFormat
        return formatter
    }()
    
    static func from(firebase snapshot: DataSnapshot) -> Event? {
        if let value = snapshot.value as? [String:Any],
            let id = value[Constants.Event.properties.firebaseNodes.id] as? String,
            let name = value[Constants.Event.properties.firebaseNodes.name] as? String,
            let startTimeString = value[Constants.Event.properties.firebaseNodes.start] as? String,
            let start = Event.dateFormatter.date(from: startTimeString.substring(to: startTimeString.index(startTimeString.endIndex, offsetBy: -5))) {
            
            let event = Event(id: id, name: name, start: start)
            event.description = value[Constants.Event.properties.firebaseNodes.description] as? String
            if let pictureURLString = value[Constants.Event.properties.firebaseNodes.pictureURL] as? String {
                event.pictureURL = URL(string: pictureURLString)
            }
            if let coverURLString = value[Constants.Event.properties.firebaseNodes.coverURL] as? String {
                event.coverURL = URL(string: coverURLString)
            }
            if let endTimeString = value[Constants.Event.properties.firebaseNodes.end] as? String {
                event.end = Event.dateFormatter.date(from: endTimeString)
            }
            if let attendingCount = value[Constants.Event.properties.firebaseNodes.attendingCount] as? Int {
                event.attendingCount = attendingCount
            }
            if let interestedCount = value[Constants.Event.properties.firebaseNodes.interestedCount] as? Int {
                event.interestedCount = interestedCount
            }
            if let noReplyCount = value[Constants.Event.properties.firebaseNodes.noReplyCount] as? Int {
                event.noReplyCount = noReplyCount
            }
            if let type = value[Constants.Event.properties.firebaseNodes.type] as? String {
                event.type = type
            }
            event.place = Place.from(firebase: snapshot.childSnapshot(forPath: Constants.Event.Place.firebaseNode))
            return event
            
        } else {
            print("Failed to create Event from Firebase snapshot. Nil or missing required data.", snapshot)
            return nil
        }
    }
    
    static func from(graphAPI dict: [String:Any]?) -> Event? {
        
        if let dict = dict,
            let id = dict[Constants.Event.properties.graphAPIKeys.id] as? String,
            let name = dict[Constants.Event.properties.graphAPIKeys.name] as? String,
            let startTimeString = dict[Constants.Event.properties.graphAPIKeys.start] as? String,
            let start = Event.dateFormatter.date(from: startTimeString.substring(to: startTimeString.index(startTimeString.endIndex, offsetBy: -5))){
            
            let event = Event(id: id, name: name, start: start)
            event.description = dict[Constants.Event.properties.graphAPIKeys.description] as? String
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
            if let cover = dict[Constants.Event.properties.graphAPIKeys.cover] as? [String:Any] {
                if let coverSource = cover[Constants.Event.properties.graphAPIKeys.coverSource] as? String {
                    event.coverURL = URL(string: coverSource)
                }
            }
            event.place = Place.from(graphAPI: dict[Constants.Event.Place.graphAPIKey] as? [String:Any])
            if let attendingCount = dict[Constants.Event.properties.graphAPIKeys.attendingCount] as? Int {
                event.attendingCount = attendingCount
            }
            if let interestedCount = dict[Constants.Event.properties.graphAPIKeys.interestedCount] as? Int {
                event.interestedCount = interestedCount
            }
            if let noReplyCount = dict[Constants.Event.properties.graphAPIKeys.noReplyCount] as? Int {
                event.noReplyCount = noReplyCount
            }
            if let rsvpStatus = dict[Constants.Event.properties.graphAPIKeys.rsvpStatus] as? String {
                event.rsvpStatus = rsvpStatus
            }
            event.type = dict[Constants.Event.properties.graphAPIKeys.type] as? String
            return event
            
        } else {
            print("Failed to create Event from Graph API dictionary. Nil or missing required data.", dict as Any)
            return nil
        }

    }
    
    func toDictionary() -> [String:Any] {
        var dict: [String:Any] = [:]
        dict[Constants.Event.properties.firebaseNodes.id] = self.id
        dict[Constants.Event.properties.firebaseNodes.name] = self.name
        dict[Constants.Event.properties.firebaseNodes.start] = Event.dateFormatter.string(from: start)
        if let end = self.end {
            dict[Constants.Event.properties.firebaseNodes.end] = Event.dateFormatter.string(from: end)
        }
        dict[Constants.Event.properties.firebaseNodes.description] = self.description
        dict[Constants.Event.properties.firebaseNodes.pictureURL] = self.pictureURL?.absoluteString
        dict[Constants.Event.properties.firebaseNodes.coverURL] = self.coverURL?.absoluteString
        dict[Constants.Event.properties.firebaseNodes.place] = self.place?.toDictionary()
        dict[Constants.Event.properties.firebaseNodes.attendingCount] = self.attendingCount
        dict[Constants.Event.properties.firebaseNodes.interestedCount] = self.interestedCount
        dict[Constants.Event.properties.firebaseNodes.noReplyCount] = self.noReplyCount
        return dict
    }
    
    func loadMatches(completion: (() -> ())? = nil) {
        User.current.value?.matchesRef.queryOrdered(byChild: "\(Constants.User.Match.properties.firebaseNodes.events)/\(id)").queryStarting(atValue: 0).observeSingleEvent(of: .value, with: { (snapshot) in
            let matchesGroup = DispatchGroup()
            self.matches = []
            for matchSnapshot in snapshot.children {
                if let matchSnapshot = matchSnapshot as? DataSnapshot {
                    let user = User(uid: matchSnapshot.key)
                    matchesGroup.enter()
                    user.profile.loadFromFirebase(completion: { (_, error) in
                        if error == nil {
                            //for i in 0..<10 {
                                self.matches.append(user)
                            //}
                            matchesGroup.leave()
                        }
                    })
                }
            }
            matchesGroup.notify(queue: .main, execute: {
                completion?()
            })
        })
    }
    
    static func get(for id: String, completion: ((Event?) -> Void)? = nil) {
        let ref = Database.database().reference().child(Constants.Event.firebaseNode).child(id)
        ref.observeSingleEvent(of: .value, with: { snapshot in
            //print("GOT SNAPSHOT", snapshot)
            completion?(from(firebase: snapshot))
        })
    }
    
    func save(completion: ((Error?) -> Void)? = nil) {
        ref.setValue(toDictionary(), withCompletionBlock: { error, ref in
            completion?(error)
        })
    }
    
    static func search(query:String) -> Observable<[Event]> {
        return Observable.create { observer in
            SearchEventsGraphRequest(query: query).start { response, result in
                switch result {
                case .success(let response):
                    //print(response)
                    observer.onNext(response.events)
                    observer.onCompleted()
                case .failed(let error):
                    print("SearchEventsGraphRequest failed: \(error.localizedDescription)")
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }

}

extension Event {
    enum RSVP: String {
        case attending
        case unsure
        case notReplied = "not_replied"
        case iWasRecommendedOthers = "i_was_recommended_others"
        case otherWasRecommendedMine = "other_was_recommended_mine"
    }
}
