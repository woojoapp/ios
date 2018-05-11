//
// Created by Edouard Goossens on 11/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase
import CodableFirebase
import RxSwift
import Promises

class UserCandidatesRepository {

    private let firebaseAuth = Auth.auth()
    private let firebaseDatabase = Database.database()

    static let shared = UserCandidatesRepository()
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

    func getOtherUserCommonInfo(uid: String?, otherUserKind: OtherUser.Kind) -> Observable<CommonInfo?> {
        guard let uid = uid else { return nil }
        let otherUserReference: DatabaseReference
        switch (otherUserKind) {
        case .candidate:
            otherUserReference = getCurrentUserDatabaseReference().child("candidates").child(uid)
        case .match:
            otherUserReference = firebaseDatabase.reference().child("matches").child(getUid()).child(uid)
        }
        let otherUserDataSnapshot = otherUserReference.rx_observeEvent(event: .value)
        let otherUser = otherUserDataSnapshot.map { try CommonInfo(from: $0) }
        return otherUser
    }
}
