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

class EventRepository: BaseRepository {
    static var shared = EventRepository()
    
    private func getEventReference(eventId: String) -> DatabaseReference {
        return firebaseDatabase
            .reference()
            .child("events")
            .child(eventId)
    }
    
    func get(eventId: String) -> Observable<Event?> {
        return withCurrentUser { _ in
            return self.getEventReference(eventId: eventId)
            .rx_observeEvent(event: .value)
            .map { Event(from: $0) }
        }
    }
}
