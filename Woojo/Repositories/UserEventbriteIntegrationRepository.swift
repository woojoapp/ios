//
// Created by Edouard Goossens on 10/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import RxSwift
import Promises

class UserEventbriteIntegrationRepository: EventIdsToEventsConversion {
    private let firebaseAuth = Auth.auth()
    private let firebaseDatabase = Database.database()

    static let shared = UserEventbriteIntegrationRepository()
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

    private func getEventbriteIntegrationReference() -> DatabaseReference {
        return getCurrentUserDatabaseReference().child("integrations/eventbrite")
    }

    private func getEventbriteAccessTokenReference() -> DatabaseReference {
        return getEventbriteIntegrationReference().child("access_token")
    }

    private func getEventbriteEventIdsReference() -> DatabaseReference {
        return getEventbriteIntegrationReference().child("events")
    }
    
    func isEventbriteIntegrated() -> Observable<Bool> {
        return getEventbriteAccessTokenReference()
            .rx_observeEvent(event: .value)
            .map { $0.exists() }
    }

    func removeEventbriteIntegration() -> Promise<Void> {
        return getEventbriteIntegrationReference().removeValuePromise()
    }

    func getEventbriteEvents() -> Observable<[Event]> {
        return getEventbriteEventIdsReference()
                .rx_observeEvent(event: .value)
                .flatMap({ self.transformEventIdsToEvents(dataSnapshot: $0, source: .eventbrite) { $0.key } })
    }

    func getEventbriteAccessToken() -> Observable<String?> {
        return getEventbriteAccessTokenReference()
                .rx_observeEvent(event: .value)
                .map {
                    print("EVVENT", $0)
                    return $0.value as? String
                }
    }
    
    func setEventbriteAccessToken(accessToken: String) -> Promise<Void> {
        return getEventbriteAccessTokenReference().setValuePromise(value: accessToken)
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
        return getEventbriteEventIdsReference().setValuePromise(value: eventIds)
    }

    enum EventbriteIntegrationError: Error {
        case syncNoAccessToken
        case syncRequestFailed(error: Error)
        case syncHttpError(response: HTTPURLResponse)
        case syncJsonDecodeError(error: Error)
    }
}
