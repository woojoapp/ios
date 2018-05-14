//
// Created by Edouard Goossens on 11/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import RxSwift
import Promises

class UserMatchRepository {
    private let firebaseAuth = Auth.auth()
    private let firebaseDatabase = Database.database()

    static var shared = UserMatchRepository()

    private init() {}

    private func getUid() -> String { return firebaseAuth.currentUser!.uid }

    func getMatch(uid: String) -> Observable<OtherUser?> {
        return Observable.combineLatest(getCommonInfo(uid: uid), UserProfileRepository.shared.getProfile(uid: uid)) { commonInfo, profile -> OtherUser in
            let candidate = Match(uid: uid)
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
        return firebaseDatabase.reference().child("matches").child(getUid()).child(uid)
            .rx_observeEvent(event: .value)
            .map { CommonInfo(from: $0) }
    }
    
    func getMatchesReference() -> DatabaseReference {
        return firebaseDatabase.reference()
            .child("matches")
            .child(getUid())
    }
    
    func getEventMatchesQuery(eventId: String) -> DatabaseQuery {
        return firebaseDatabase.reference()
            .child("matches")
            .child(getUid())
            .queryOrdered(byChild: "events/\(eventId)")
            .queryStarting(atValue: 0.0)
    }
}
