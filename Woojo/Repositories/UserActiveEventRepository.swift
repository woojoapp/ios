//
// Created by Edouard Goossens on 10/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import RxSwift
import Promises

class UserActiveEventRepository {
    private let firebaseAuth = Auth.auth()
    private let firebaseDatabase = Database.database()

    static let shared = UserActiveEventRepository()
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

    private func getActiveEventsInfoReference() -> DatabaseReference {
        return getCurrentUserDatabaseReference().child("events")
    }

    func getActiveEventsInfo() -> Observable<DataSnapshot> {
        return getActiveEventsInfoReference()
                .rx_observeEvent(event: .value)
    }

    func activateEvent(event: Event, completion: @escaping ((Error?, DatabaseReference) -> Void)) {
        getActiveEventsInfoReference().child(event.id).setValue(event.rsvpStatus, withCompletionBlock: completion)
    }

    func deactivateEvent(event: Event, completion: @escaping ((Error?, DatabaseReference) -> Void)) {
        getActiveEventsInfoReference().child(event.id).removeValue(completionBlock: completion)
    }
}
