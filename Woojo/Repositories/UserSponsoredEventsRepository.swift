//
// Created by Edouard Goossens on 10/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import RxSwift
import Promises

class UserSponsoredEventsRepository: EventIdsToEventsConverter {
    private let firebaseDatabase = Database.database()

    static let shared = UserSponsoredEventsRepository()
    
    private init() {}

    private func getSponsoredEventIdsReference() -> DatabaseReference {
        return firebaseDatabase.reference().child("recommendedEvents")
    }

    func getSponsoredEvents() -> Observable<[User.Event]> {
        return getSponsoredEventIdsReference()
                .rx_observeEvent(event: .value)
                .flatMap({ dataSnapshot -> Observable<[User.Event]> in
                    let arrayOfObservables = dataSnapshot.children.reduce(into: [Observable<User.Event?>](), { observables, childSnapshot in
                        if let childSnapshot = childSnapshot as? DataSnapshot {
                            let event = EventRepository.shared.get(eventId: childSnapshot.key).map({ e -> User.Event? in
                                if let e = e {
                                    return User.Event(event: e, connection: User.Event.Connection.sponsored)
                                }
                                return nil
                            })
                            observables.append(event)
                        }
                    })
                    print("EVV SPO", arrayOfObservables.count)
                    if dataSnapshot.childrenCount == 0 {
                        return Observable.of([])
                    }
                    return Observable
                        .combineLatest(arrayOfObservables)
                        .map({ $0.flatMap{ $0 } as [User.Event] })
                })
    }
}
