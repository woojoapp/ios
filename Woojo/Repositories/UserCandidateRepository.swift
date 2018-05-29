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

class UserCandidateRepository: BaseRepository, EventIdsToEventsConverter, AppScopedIdsToUsersConverter {

    static let shared = UserCandidateRepository()
    override private init() {}

    func getCandidate(uid: String) -> Observable<Candidate?> {
        return Observable.combineLatest(getCommonInfo(uid: uid), UserProfileRepository.shared.getProfile(uid: uid)) { commonInfo, profile -> Candidate in
            let candidate = Candidate(uid: uid)
            if let commonInfo = commonInfo {
                candidate.commonInfo = commonInfo
            }
            if let profile = profile {
                candidate.profile = profile
            }
            return candidate
        }
    }
    
    private func getCommonInfo(uid: String) -> Observable<CommonInfo?> {
        let commonInfoDataSnapshot = withCurrentUser { $0.child("candidates").child(uid).rx_observeEvent(event: .value) }
        let commonInfo = commonInfoDataSnapshot.map { CommonInfo(from: $0) }
        let commonEvents = commonInfoDataSnapshot.flatMap { self.transformEventIdsToEvents(dataSnapshot: $0.childSnapshot(forPath: "events"), source: .recommended) { $0.key } }
        let commonFriends = commonInfoDataSnapshot.flatMap { self.transformAppScopedIdsToUsers(dataSnapshot: $0.childSnapshot(forPath: "friends")) }
        return Observable.combineLatest(commonInfo, commonEvents, commonFriends) { info, events, friends -> CommonInfo? in
            info?.events = events.reduce(into: [String: Event](), { $0[$1.id!] = $1 })
            info?.friends = friends.reduce(into: [String: User](), { $0[$1.uid] = $1 })
            return info
        }
    }

    func getCandidatesQuery() -> Observable<DatabaseQuery> {
        return getCurrentUserDatabaseReference().map { $0.child("candidates").queryOrdered(byChild: "added") }
    }

    func removeCandidate(uid: String) -> Promise<Void> {
        return doWithCurrentUser { $0.child("candidates").child(uid).removeValuePromise() }
    }

    /* func getOtherUserCommonInfo<T: OtherUser>(uid: String?, otherUserType: T.Type) -> Observable<CommonInfo?> {
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
            let otherUser = otherUserDataSnapshot.map { CommonInfo(from: $0) }
            return otherUser
        }
        return Observable.of(nil)
    } */
}
