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

class UserFacebookIntegrationRepository: BaseRepository, EventIdsToEventsConversion {
    static let shared = UserFacebookIntegrationRepository()
    
    override private init() {
        super.init()
    }

    func removeFacebookIntegration() -> Promise<Void> {
        return doWithCurrentUser { $0.child("integrations/facebook").removeValuePromise() }
    }
    
    func isFacebookIntegrated() -> Observable<Bool> {
        return withCurrentUser {
            $0.child("integrations/facebook/access_token")
                .rx_observeEvent(event: .value)
                .map { $0.exists() }
        }
    }

    func getFacebookEvents() -> Observable<[Event]> {
        return withCurrentUser {
            $0.child("integrations/facebook/events")
                .rx_observeEvent(event: .value)
                .flatMap({ self.transformEventIdsToEvents(dataSnapshot: $0, source: .facebook) { $0.key } })
        }
    }

    func getFacebookAccessToken() -> Observable<String?> {
        return withCurrentUser {
            $0.child("integrations/facebook/access_token")
                .rx_observeEvent(event: .value)
                .map { $0.value as? String }
        }
    }

    func setPageLikes(pageLikes: [PageLike]) -> Promise<Void> {
        let dictionary = pageLikes.reduce(into: [String: [String: Any]]()) { result, pageLike in
            if let id = pageLike.id { result[id] = pageLike.dictionary }
        }
        return doWithCurrentUser { $0.child("page-likes").setValuePromise(value: dictionary) }
    }

    func setFriends(friends: [Friend]) -> Promise<Void> {
        let dictionary = friends.reduce(into: [String: [String: Any]]()) { result, friend in
            if let id = friend.id { result[id] = friend.dictionary }
        }
        return doWithCurrentUser { $0.child("friends").setValuePromise(value: dictionary) }
    }
}
