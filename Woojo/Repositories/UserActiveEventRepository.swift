//
// Created by Edouard Goossens on 10/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import RxSwift
import Promises

class UserActiveEventRepository: BaseRepository {
    static let shared = UserActiveEventRepository()
    
    override private init() {
        super.init()
    }

    func getActiveEventsInfo() -> Observable<DataSnapshot> {
        return withCurrentUser {
                $0.child("events")
                    .rx_observeEvent(event: .value)
        }
    }

    func activateEvent(eventId: String, rsvpStatus: String? = "unsure") -> Promise<Void> {
        return doWithCurrentUser { $0.child("events").child(eventId).setValuePromise(value: rsvpStatus) }
    }

    func deactivateEvent(eventId: String) -> Promise<Void> {
        return doWithCurrentUser { $0.child("events").child(eventId).removeValuePromise() }
    }
    
    enum UserActiveEventRepositoryError: Error {
        case eventIdMissing
    }
}
