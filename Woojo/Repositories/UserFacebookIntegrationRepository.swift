//
// Created by Edouard Goossens on 10/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import Foundation

import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import RxSwift
import Promises

class UserFacebookIntegrationRepository: EventIdsToEventsConversion {
    private let firebaseAuth = Auth.auth()
    private let firebaseDatabase = Database.database()

    static let shared = UserFacebookIntegrationRepository()
    private init() {}

    private func getUid() -> String? { return firebaseAuth.currentUser!.uid }

    private func getUserDatabaseReference(uid: String) -> DatabaseReference {
        return firebaseDatabase
                .reference()
                .child("users")
                .child(uid)
    }

    private func getCurrentUserDatabaseReference() -> DatabaseReference {
        return getUserDatabaseReference(uid: uid)
    }

    private func getFacebookIntegrationReference() -> DatabaseReference {
        return getCurrentUserDatabaseReference().child("integrations/facebook")
    }

    private func getFacebookAccessTokenReference() -> DatabaseReference {
        return getFacebookIntegrationReference().child("access_token")
    }

    private func getFacebookEventIdsReference() -> DatabaseReference {
        return getFacebookIntegrationReference().child("events")
    }

    func removeFacebookIntegration(completion: @escaping (Error?, DatabaseReference) -> Void) {
        getFacebookIntegrationReference().removeValue(completionBlock: completion)
    }

    func getFacebookEvents() -> Observable<[Event]> {
        return getFacebookEventIdsReference()
                .rx_observeEvent(event: .value)
                .flatMap({ self.transformEventIdsToEvents(dataSnapshot: $0, source: .facebook) { $0.key } })
    }

    func getFacebookAccessToken() -> Observable<DataSnapshot> {
        return getFacebookAccessTokenReference().rx_observeEvent(event: .value)
    }

    func setPageLikes(pageLikes: [PageLike]) -> Promise<Void> {
        let dictionary = pageLikes.reduce(into: [String: PageLike]()) { result, pageLike in
            if let id = pageLike.id { result[id] = pageLike }
        }
        return getCurrentUserDatabaseReference().child("page-likes").setValuePromise(value: dictionary)
    }

    func setFriends(friends: [Friend]) -> Promise<Void> {
        let dictionary = friends.reduce(into: [String: Friend]()) { result, friend in
            if let id = friend.id { result[id] = friend }
        }
        return getCurrentUserDatabaseReference().child("friends").setValuePromise(value: dictionary)
    }
}
