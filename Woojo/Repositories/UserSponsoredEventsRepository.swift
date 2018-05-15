//
// Created by Edouard Goossens on 10/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import RxSwift
import Promises

class UserSponsoredEventsRepository: EventIdsToEventsConversion {
    private let firebaseDatabase = Database.database()

    static let shared = UserSponsoredEventsRepository()
    
    private init() {}

    private func getSponsoredEventIdsReference() -> DatabaseReference {
        return firebaseDatabase.reference().child("recommendedEvents")
    }

    func getSponsoredEvents() -> Observable<[Event]> {
        return getSponsoredEventIdsReference()
                .rx_observeEvent(event: .value)
                .flatMap({ self.transformEventIdsToEvents(dataSnapshot: $0, source: .sponsored) { $0.key } })
    }
}
