//
// Created by Edouard Goossens on 10/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import RxSwift
import Promises

class UserEventbriteIntegrationRepository: BaseRepository, EventIdsToEventsConverter {
    static let shared = UserEventbriteIntegrationRepository()
    
    override private init() {
        super.init()
    }
    
    /* func isEventbriteIntegrated() -> Observable<Bool> {
        return withCurrentUser {
            $0.child("integrations/eventbrite/access_token")
                .rx_observeEvent(event: .value)
                .map { $0.exists() }
        }
    } */

    func removeEventbriteIntegration() -> Promise<Void> {
        return doWithCurrentUser { $0.child("integrations/eventbrite").removeValuePromise() }
    }

    func getEventbriteEvents() -> Observable<[User.Event]> {
        return withCurrentUser {
            $0.child("integrations/eventbrite/events")
                .rx_observeEvent(event: .value)
                .flatMap({ dataSnapshot -> Observable<[User.Event]> in
                    let arrayOfObservables = dataSnapshot.children.reduce(into: [Observable<User.Event?>](), { observables, childSnapshot in
                        if let childSnapshot = childSnapshot as? DataSnapshot {
                            let event = EventRepository.shared.get(eventId: childSnapshot.key).map({ e -> User.Event? in
                                if let e = e {
                                    return User.Event(event: e, connection: User.Event.Connection.eventbriteTicket)
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
                        //.filter({ !$0.contains(where: { $0 == nil }) })
                        .map({ $0.flatMap{ $0 } as [User.Event] })
                })
            }.catchError({ (error) -> Observable<[User.Event]> in
                print("NNEW CATCH ERROR", error)
                return Observable.of([])
            })
    }

    func getEventbriteAccessToken() -> Observable<String?> {
        return withCurrentUser {
            $0.child("integrations/eventbrite/access_token")
                .rx_observeEvent(event: .value)
                .map {
                    print("EVVENT", $0)
                    return $0.value as? String
                }
        }
    }
    
    func setEventbriteAccessToken(accessToken: String) -> Promise<Void> {
        return doWithCurrentUser {
            $0.child("integrations/eventbrite/access_token")
                .setValuePromise(value: accessToken)
        }
    }

    func syncEventbriteEvents() -> Promise<Void> {
        return getEventbriteAccessToken().toPromise().then { accessToken in
            if let accessToken = accessToken {
                return EventbriteRepository.shared.getEvents(accessToken: accessToken).then { events in
                    print("EVVENT", events)
                    let eventIds = events.reduce(into: [String: Bool](), { $0["eventbrite_\($1.id)"] = true })
                    return self.writeEventbriteEventIds(eventIds: eventIds)
                }
            } else {
                return Promise(EventbriteIntegrationError.syncNoAccessToken)
            }
        }
    }

    private func writeEventbriteEventIds(eventIds: [String: Bool]) -> Promise<Void> {
        return doWithCurrentUser {
            $0.child("integrations/eventbrite/events")
                .setValuePromise(value: eventIds)
        }
    }

    enum EventbriteIntegrationError: Error {
        case syncNoAccessToken
        case syncRequestFailed(error: Error)
        case syncHttpError(response: HTTPURLResponse)
        case syncJsonDecodeError(error: Error)
    }
}
