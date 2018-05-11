//
// Created by Edouard Goossens on 10/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import FirebaseDatabase
import RxSwift

typealias DataSnapshotToEventIdBlock = (DataSnapshot) -> String?

protocol EventIdsToEventsConversion {

}

extension EventIdsToEventsConversion {
    func transformEventIdsToEvents(dataSnapshot: DataSnapshot, source: Event.Source, getEventIdFromDataSnapshot: DataSnapshotToEventIdBlock) -> Observable<[Event]> {
        let arrayOfObservables = dataSnapshot.children.reduce(into: [Observable<Event?>](), { (observables, childSnapshot) in
            if let childSnapshot = childSnapshot as? DataSnapshot,
               let eventId = getEventIdFromDataSnapshot(childSnapshot) {
                let event = EventRepository.shared.get(eventId: eventId).startWith(nil).map({ e -> Event? in
                    e?.source = source
                    return e
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
                .map({ $0.flatMap{ $0 } as [Event] })
    }
}
