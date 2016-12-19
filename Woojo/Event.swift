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
    var description: String?
    var attendingCount: Int?
    
    var ref: FIRDatabaseReference {
        get {
            return FIRDatabase.database().reference().child(Constants.Event.firebaseNode).child(id)
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
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = Constants.Event.dateFormat
        return formatter
    }()
    
    static func from(firebase snapshot: FIRDataSnapshot) -> Event? {
        
        if let value = snapshot.value as? [String:Any],
            let id = value[Constants.Event.properties.firebaseNodes.id] as? String,
            let name = value[Constants.Event.properties.firebaseNodes.name] as? String,
            let startTimeString = value[Constants.Event.properties.firebaseNodes.start] as? String,
            let start = Event.dateFormatter.date(from: startTimeString) {
            
            let event = Event(id: id, name: name, start: start)
            event.description = value[Constants.Event.properties.firebaseNodes.description] as? String
            if let pictureURLString = value[Constants.Event.properties.firebaseNodes.pictureURL] as? String {
                event.pictureURL = URL(string: pictureURLString)
            }
            if let endTimeString = value[Constants.Event.properties.firebaseNodes.end] as? String {
                event.end = Event.dateFormatter.date(from: endTimeString)
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
            let start = Event.dateFormatter.date(from: startTimeString){
            
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
            event.place = Place.from(graphAPI: dict[Constants.Event.Place.graphAPIKey] as? [String:Any])
            if let attendingCount = dict[Constants.Event.properties.graphAPIKeys.attendingCount] as? Int {
                event.attendingCount = attendingCount
            }
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
        dict[Constants.Event.properties.firebaseNodes.place] = self.place?.toDictionary()
        return dict
    }
    
    static func get(for id: String, completion: @escaping (Event?) -> Void) {
        FIRDatabase.database().reference().child(Constants.Event.firebaseNode).child(id).observeSingleEvent(of: .value, with: { snapshot in
            completion(from(firebase: snapshot))
        })
    }
    
    func save(completion: ((Error?) -> Void)?) {
        ref.setValue(toDictionary(), withCompletionBlock: { error, ref in
            completion?(error)
        })
    }
    
    static func search(query:String) -> Observable<[Event]> {
        return Observable.create { observer in
            SearchEventsGraphRequest(query: query).start { response, result in
                switch result {
                case .success(let response):
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
