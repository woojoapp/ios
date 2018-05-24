//
// Created by Edouard Goossens on 11/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import RxSwift
import Promises

class UserMatchRepository: BaseRepository, EventIdsToEventsConverter, AppScopedIdsToUsersConverter {
    
    static var shared = UserMatchRepository()
    override private init() {}

    func getMatch(uid: String) -> Observable<OtherUser?> {
        return Observable.combineLatest(getCommonInfo(uid: uid), UserProfileRepository.shared.getProfile(uid: uid)) { commonInfo, profile -> OtherUser in
            let match = Match(uid: uid)
            if let commonInfo = commonInfo {
                match.commonInfo = commonInfo
            }
            if let profile = profile {
                match.profile = profile
            }
            return match
        }
    }
    
    private func getCommonInfo(uid: String) -> Observable<CommonInfo?> {
        let commonInfoDataSnapshot = withCurrentUser { self.firebaseDatabase.reference().child("matches").child($0.key).child(uid).rx_observeEvent(event: .value) }
        let commonInfo = commonInfoDataSnapshot.map { CommonInfo(from: $0) }
        let commonEvents = commonInfoDataSnapshot.flatMap { self.transformEventIdsToEvents(dataSnapshot: $0.childSnapshot(forPath: "events"), source: .recommended) { $0.key } }
        let commonFriends = commonInfoDataSnapshot.flatMap { self.transformAppScopedIdsToUsers(dataSnapshot: $0.childSnapshot(forPath: "friends")) }
        return Observable.combineLatest(commonInfo, commonEvents, commonFriends) { info, events, friends -> CommonInfo? in
            info?.events = events.reduce(into: [String: Event](), { $0[$1.id!] = $1 })
            info?.friends = friends.reduce(into: [String: User](), { $0[$1.uid] = $1 })
            return info
        }
    }
    
    func getMatchesReference() -> Observable<DatabaseReference> {
        return getCurrentUserDatabaseReference().map { self.firebaseDatabase.reference()
            .child("matches")
            .child($0.key)
        }
    }
    
    func getEventMatchesQuery(eventId: String) -> Observable<DatabaseQuery> {
        return getCurrentUserDatabaseReference().map { self.firebaseDatabase.reference()
            .child("matches")
            .child($0.key)
            .queryOrdered(byChild: "events/\(eventId)")
            .queryStarting(atValue: 0.0)
        }
    }
}
