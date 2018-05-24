//
// Created by Edouard Goossens on 10/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import RxSwift
import Promises

class UserRecommendedEventsRepository: BaseRepository, EventIdsToEventsConverter {
    static let shared = UserRecommendedEventsRepository()
    
    override private init() {
        super.init()
    }

    func getRecommendedEvents() -> Observable<[User.Event]> {
        return withCurrentUser {
            $0.child("recommendations/events")
                .rx_observeEvent(event: .value)
                .flatMap({ dataSnapshot -> Observable<[User.Event]> in
                    let arrayOfObservables = dataSnapshot.children.reduce(into: [Observable<User.Event?>](), { observables, childSnapshot in
                        if let childSnapshot = childSnapshot as? DataSnapshot,
                            let eventId = childSnapshot.value as? String {
                            let event = EventRepository.shared.get(eventId: eventId).map({ e -> User.Event? in
                                if let e = e {
                                    return User.Event(event: e, connection: User.Event.Connection.recommended)
                                }
                                return nil
                            })
                            observables.append(event)
                        }
                    })
                    if dataSnapshot.childrenCount == 0 {
                        return Observable.of([])
                    }
                    return Observable
                        .combineLatest(arrayOfObservables)
                        .filter({ !$0.contains(where: { $0 == nil }) })
                        .map({ $0.flatMap{ $0 } as [User.Event] })
                })
        }
    }
}
