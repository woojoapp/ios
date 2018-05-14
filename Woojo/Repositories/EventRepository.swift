//
//  EventStore.swift
//  Woojo
//
//  Created by Edouard Goossens on 28/04/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseDatabase
import RxSwift

class EventRepository {
    private let firebaseDatabase = Database.database()
    static var shared = EventRepository()
    
    private init() {}
    
    private func getEventReference(eventId: String) -> DatabaseReference {
        return firebaseDatabase
            .reference()
            .child("events")
            .child(eventId)
    }
    
    func get(eventId: String) -> Observable<Event?> {
        return getEventReference(eventId: eventId)
            .rx_observeEvent(event: .value)
            .map { Event(from: $0) }
    }
}
