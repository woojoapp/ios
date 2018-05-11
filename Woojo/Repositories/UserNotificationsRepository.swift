//
// Created by Edouard Goossens on 11/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import RxSwift
import Promises

class UserNotificationsRepository {
    private let firebaseAuth = Auth.auth()
    private let firebaseDatabase = Database.database()

    static let shared = UserNotificationsRepository()
    private init() {}

    private func getUid() -> String { return firebaseAuth.currentUser!.uid }

    private func getUserDatabaseReference(uid: String) -> DatabaseReference {
        return firebaseDatabase
                .reference()
                .child("users")
                .child(uid)
    }

    private func getCurrentUserDatabaseReference() -> DatabaseReference {
        return getUserDatabaseReference(uid: getUid())
    }

    func setNotificationsState(type: String, enabled: Bool) -> Promise<Void> {
        return getCurrentUserDatabaseReference()
                .child("settings")
                .child("notifications")
                .child(type)
                .setValuePromise(value: enabled)
    }

    func getNotificationsState(type: String) -> Observable<Bool> {
        return getCurrentUserDatabaseReference()
                .child("settings")
                .child("notifications")
                .child(type)
                .rx_observeEvent(event: .value)
                .map { $0.value as? Bool ?? false }
    }
}
