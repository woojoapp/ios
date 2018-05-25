//
// Created by Edouard Goossens on 10/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import Foundation
import FacebookCore
import FacebookLogin
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
        return FacebookRepository.shared.deletePermission(permission: "user_events").then { _ in
            return wrap { handler in AccessToken.refreshCurrentToken(handler) }
        }.then { accessToken in
            if let accessToken = accessToken {
                return UserFacebookIntegrationRepository.shared.setAccessToken(accessToken: accessToken.authenticationToken)
            }
            return Promise(FacebookIntegrationError.removePermissionNoAccessToken)
        }.then {
            return self.doWithCurrentUser { $0.child("integrations/facebook/events").removeValuePromise() }
        }
    }
    
    func isFacebookIntegrated() -> Observable<Bool> {
        return withCurrentUser {
            $0.child("integrations/facebook/accessToken")
                .rx_observeEvent(event: .value)
                .map { dataSnapshot -> AccessToken? in
                    if let authenticationToken = dataSnapshot.value as? String {
                        return AccessToken(authenticationToken: authenticationToken)
                    }
                    return nil
                }.flatMapLatest { accessToken -> Observable<Bool> in
                    if let accessToken = accessToken {
                        return self.isPermissionGranted(permission: "user_events", accessToken: accessToken)
                    }
                    return Observable.just(false)
                }
        }
    }
    
    private func isPermissionGranted(permission: String, accessToken: AccessToken) -> Observable<Bool> {
        return Observable.create { observer in
            FacebookRepository.shared.getPermissions(accessToken: accessToken).then { permissions in
                observer.onNext(permissions.contains(where: { $0.permission == "user_events" && $0.status == "granted" }))
                observer.onCompleted()
            }.catch { error in
                observer.onError(error)
            }
            return Disposables.create()
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
            $0.child("integrations/facebook/accessToken")
                .rx_observeEvent(event: .value)
                .map { $0.value as? String }
        }
    }
    
    func setAccessToken(accessToken: String) -> Promise<Void>{
        return doWithCurrentUser { $0.child("integrations/facebook/accessToken").setValuePromise(value: accessToken) }
    }
    
    func syncFacebookEvents(viewController: UIViewController) -> Promise<Void> {
        return getFacebookAccessToken().toPromise().then { authenticationToken in
            if let authenticationToken = authenticationToken {
                let accessToken = AccessToken(authenticationToken: authenticationToken)
                if let grantedPermissions = accessToken.grantedPermissions,
                    grantedPermissions.contains(Permission(name: "user_events")) {
                    return LoginManager.shared.setEventsFromFacebook()
                } else {
                    return LoginManager.shared.facebookLogin(viewController: viewController, readPermissions: [ReadPermission.userEvents]).then { _ in
                        return LoginManager.shared.setEventsFromFacebook()
                    }
                }
            } else {
                return Promise(FacebookIntegrationError.syncNoAccessToken)
            }
        }
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
    
    enum FacebookIntegrationError: Error {
        case syncNoAccessToken
        case removePermissionNoAccessToken
    }
}
