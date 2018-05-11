//
// Created by Edouard Goossens on 10/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import RxSwift
import Promises

class UserRecommendedEventsRepository: EventIdsToEventsConversion {
    private let firebaseAuth = Auth.auth()
    private let firebaseDatabase = Database.database()
    private let firebaseStorage = Storage.storage()

    static let shared = UserRecommendedEventsRepository()
    private init() {}

    private func getUid() -> String { return firebaseAuth.currentUser!.uid }

    private func getUserDatabaseReference(uid: String) -> DatabaseReference {
        return firebaseDatabase
                .reference()
                .child("users")
                .child(uid)
    }

    private func getCurrentUserDatabaseReference() -> DatabaseReference {
        return getUserDatabaseReference(uid: uid)
    }

    private func getRecommendedEventIdsReference() -> DatabaseReference {
        return getCurrentUserDatabaseReference().child("recommendations/events")
    }

    func getRecommendedEvents() -> Observable<[Event]> {
        return getRecommendedEventIdsReference()
                .rx_observeEvent(event: .value)
                .flatMap({ self.transformEventIdsToEvents(dataSnapshot: $0, source: .recommended) { $0.value as? String } })
    }
}
