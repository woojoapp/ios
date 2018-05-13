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

class UserCandidateRepository {

    private let firebaseAuth = Auth.auth()
    private let firebaseDatabase = Database.database()

    static let shared = UserCandidateRepository()
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

    func getCandidate(uid: String) -> Observable<OtherUser?> {
        return getCurrentUserDatabaseReference().child("candidates").child(uid)
                .rx_observeEvent(event: .value)
                .map { try Candidate(from: $0) }
    }

    func getCandidatesQuery() -> DatabaseQuery {
        return getCurrentUserDatabaseReference().child("candidates").queryOrdered(byChild: "added")
    }

    func removeCandidate(uid: String) -> Promise<Void> {
        return getCurrentUserDatabaseReference().child("candidates").child(uid).removeValuePromise()
    }

    func getOtherUserCommonInfo<T: OtherUser>(uid: String?, otherUserType: T.Type) -> Observable<CommonInfo?> {
        guard let uid = uid else { return Observable.of(nil) }
        let otherUserReference: DatabaseReference?
        switch (otherUserType) {
        case is Candidate.Type:
            otherUserReference = getCurrentUserDatabaseReference().child("candidates").child(uid)
        case is Match.Type:
            otherUserReference = firebaseDatabase.reference().child("matches").child(getUid()).child(uid)
        default:
            otherUserReference = nil
        }
        if let otherUserReference = otherUserReference {
            let otherUserDataSnapshot = otherUserReference.rx_observeEvent(event: .value)
            let otherUser = otherUserDataSnapshot.map { try CommonInfo(from: $0) }
            return otherUser
        }
        return Observable.of(nil)
    }
}
