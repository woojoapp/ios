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

class UserFacebookIntegrationRepository: BaseRepository, EventIdsToEventsConverter {
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

    func getFacebookEvents() -> Observable<[User.Event]> {
        return withCurrentUser {
            $0.child("integrations/facebook/events")
                .rx_observeEvent(event: .value)
                .flatMap({ dataSnapshot -> Observable<[User.Event]> in
                    let arrayOfObservables = dataSnapshot.children.reduce(into: [Observable<User.Event?>](), { observables, childSnapshot in
                        if let childSnapshot = childSnapshot as? DataSnapshot,
                            let connectionString = childSnapshot.childSnapshot(forPath: "rsvpStatus").value as? String {
                            let event = EventRepository.shared.get(eventId: childSnapshot.key).map({ e -> User.Event? in
                                if let e = e, let connection = User.Event.Connection(rawValue: connectionString) {
                                    return User.Event(event: e, connection: connection)
                                }
                                return nil
                            })
                            observables.append(event)
                        }
                    })
                    if dataSnapshot.childrenCount == 0 {
                        return Observable.of([])
                    }
                    return Observable
                        .combineLatest(arrayOfObservables)
                        .filter({ !$0.contains(where: { $0 == nil }) })
                        .map({ $0.flatMap{ $0 } as [User.Event] })
                })
        }
    }

    func getFacebookAccessToken() -> Observable<String?> {
        return withCurrentUser {
            $0.child("integrations/facebook/access_token")
                .rx_observeEvent(event: .value)
                .map { $0.value as? String }
        }
    }
    
    func setAccessToken(accessToken: String) -> Promise<Void>{
        return doWithCurrentUser { $0.child("integrations/facebook/accessToken").setValuePromise(value: accessToken) }
    }
    
    func setAppScopedId(appScopedId: String) -> Promise<Void>{
        return doWithCurrentUser { $0.child("integrations/facebook/appScopedId").setValuePromise(value: appScopedId) }
    }
    
    func setEvents(events: [GraphAPI.Event]) -> Promise<Void> {
        let dictionary = events.reduce(into: [String: [String: Any]]()) { result, event in
            if let id = event.id { result[id] = ["rsvpStatus": event.rsvpStatus ?? Event.RSVP.unsure.rawValue] }
        }
        return doWithCurrentUser { $0.child("integrations/facebook/events").setValuePromise(value: dictionary) }
    }

    func setPageLikes(pageLikes: [PageLike]) -> Promise<Void> {
        let dictionary = pageLikes.reduce(into: [String: [String: Any]]()) { result, pageLike in
            if let id = pageLike.id { result[id] = pageLike.dictionary }
        }
        return doWithCurrentUser { $0.child("integrations/facebook/pageLikes").setValuePromise(value: dictionary) }
    }

    func setFriends(friends: [Friend]) -> Promise<Void> {
        let dictionary = friends.reduce(into: [String: [String: Any]]()) { result, friend in
            if let id = friend.id { result[id] = friend.dictionary }
        }
        return doWithCurrentUser { $0.child("integrations/facebook/friends").setValuePromise(value: dictionary) }
    }
}
