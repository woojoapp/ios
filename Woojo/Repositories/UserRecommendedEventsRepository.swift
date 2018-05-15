//
// Created by Edouard Goossens on 10/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import RxSwift
import Promises

class UserRecommendedEventsRepository: BaseRepository, EventIdsToEventsConversion {
    static let shared = UserRecommendedEventsRepository()
    
    override private init() {
        super.init()
    }

    func getRecommendedEvents() -> Observable<[Event]> {
        return withCurrentUser {
            $0.child("recommendations/events")
                .rx_observeEvent(event: .value)
                .flatMap({ self.transformEventIdsToEvents(dataSnapshot: $0, source: .recommended) { $0.value as? String } })
        }
    }
}
