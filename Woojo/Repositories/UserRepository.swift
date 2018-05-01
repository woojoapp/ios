//
//  UserStore.swift
//  Woojo
//
//  Created by Edouard Goossens on 28/04/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase
import RxSwift

class UserRepository {
    private let firebaseAuth = Auth.auth()
    private let firebaseDatabase = Database.database()
    
    static let shared = UserRepository()
    private init() {}
    
    private func getUid() -> String? { return firebaseAuth.currentUser?.uid }
    
    private func getUserDatabaseReference(uid: String) -> DatabaseReference {
        return firebaseDatabase
            .reference()
            .child("users")
            .child(uid)
    }
    
    private func getCurrentUserDatabaseReference() -> DatabaseReference? {
        if let uid = getUid() { return getUserDatabaseReference(uid: uid) }
        return nil
    }
    
    private func getSponsoredEventIdsReference() -> DatabaseReference? {
        return firebaseDatabase.reference().child("recommendedEvents")
    }
    
    private func getRecommendedEventIdsReference() -> DatabaseReference? {
        return getCurrentUserDatabaseReference()?.child("recommendations/events")
    }
    
    private func getEventbriteIntegrationReference() -> DatabaseReference? {
        return getCurrentUserDatabaseReference()?.child("integrations/eventbrite")
    }
    
    private func getEventbriteAccessTokenReference() -> DatabaseReference? {
        return getEventbriteIntegrationReference()?.child("access_token")
    }
    
    private func getEventbriteEventIdsReference() -> DatabaseReference? {
        return getEventbriteIntegrationReference()?.child("events")
    }
    
    func removeEventbriteIntegration(completionBlock: @escaping (Error?, DatabaseReference) -> Void) {
        getEventbriteIntegrationReference()?.removeValue(completionBlock: completionBlock)
    }
    
    private func getFacebookIntegrationReference() -> DatabaseReference? {
        return getCurrentUserDatabaseReference()?.child("integrations/facebook")
    }
    
    private func getFacebookAccessTokenReference() -> DatabaseReference? {
        return getFacebookIntegrationReference()?.child("access_token")
    }
    
    private func getFacebookEventIdsReference() -> DatabaseReference? {
        return getFacebookIntegrationReference()?.child("events")
    }
    
    func removeFacebookIntegration(completion: @escaping (Error?, DatabaseReference) -> Void) {
        getFacebookIntegrationReference()?.removeValue(completionBlock: completion)
    }
    
    private func getActiveEventsInfoReference() -> DatabaseReference? {
        return getCurrentUserDatabaseReference()?.child("events")
    }
    
    private func getEventIdFromDataSnapshot(dataSnapshot: DataSnapshot, source: Event.Source) -> String? {
        switch source {
        case .eventbrite: return dataSnapshot.key
        case .facebook: return dataSnapshot.key
        case .recommended: return dataSnapshot.value as? String
        case .sponsored: return dataSnapshot.key
        }
    }
    
    func getEvents() -> Observable<[Event]> {
        guard let facebookEvents = getFacebookEvents()?.startWith([]),
        let eventbriteEvents = getEventbriteEvents()?.startWith([]),
        let recommendedEvents = getRecommendedEvents()?.startWith([]),
        let sponsoredEvents = getSponsoredEvents()?.startWith([]),
        let activeEventsInfo = getActiveEventsInfo()
            else {
                return Observable.of([])
        }
        var events = Observable.combineLatest(facebookEvents, eventbriteEvents, recommendedEvents, sponsoredEvents) { $0 + $1 + $2 + $3 }
        events = Observable.combineLatest(events, activeEventsInfo) { evs, dataSnapshot -> [Event] in
            for ev in evs {
                let isActive = dataSnapshot.hasChild(ev.id)
                ev.active = isActive
            }
            return evs
        }
        return events
    }
    
    private func getFacebookEvents() -> Observable<[Event]>? {
        return getFacebookEventIdsReference()?
            .rx_observeEvent(event: .value)
            .flatMap({ self.transformEventIdsToEvents(dataSnapshot: $0, source: .facebook) })
    }
    
    private func getEventbriteEvents() -> Observable<[Event]>? {
        return getEventbriteEventIdsReference()?
            .rx_observeEvent(event: .value)
            .flatMap({ self.transformEventIdsToEvents(dataSnapshot: $0, source: .eventbrite) })
    }
    
    private func getRecommendedEvents() -> Observable<[Event]>? {
        return getRecommendedEventIdsReference()?
            .rx_observeEvent(event: .value)
            .flatMap({ self.transformEventIdsToEvents(dataSnapshot: $0, source: .recommended) })
    }
    
    private func getSponsoredEvents() -> Observable<[Event]>? {
        return getSponsoredEventIdsReference()?
            .rx_observeEvent(event: .value)
            .flatMap({ self.transformEventIdsToEvents(dataSnapshot: $0, source: .sponsored) })
    }
    
    private func getActiveEventsInfo() -> Observable<DataSnapshot>? {
        return getActiveEventsInfoReference()?
            .rx_observeEvent(event: .value)
    }
    
    func getEventbriteAccessToken() -> Observable<DataSnapshot>? {
        return getEventbriteAccessTokenReference()?.rx_observeEvent(event: .value)
    }
    
    func getFacebookAccessToken() -> Observable<DataSnapshot>? {
        return getFacebookAccessTokenReference()?.rx_observeEvent(event: .value)
    }
    
    func syncEventbriteEvents(completion: @escaping ((Error?) -> Void)) {
        getEventbriteAccessTokenReference()?.observeSingleEvent(of: .value, with: { (snapshot) in
            if let accessToken = snapshot.value as? String {
                let url = "\(Constants.User.Integrations.Eventbrite.baseUrl)/users/me/orders?token=\(accessToken)&expand=event,event.venue,event.logo&time_filter=all"
                let request = NSMutableURLRequest(url: URL(string: url)!)
                request.httpMethod = "GET"
                let requestAPI = URLSession.shared.dataTask(with: request as URLRequest) {data, response, error in
                    if (error != nil) {
                        completion(error)
                    }
                    if let httpStatus = response as? HTTPURLResponse , httpStatus.statusCode != 200 {
                        print("Error response: \(String(describing: response))")
                    }
                    if error == nil && data != nil {
                        do {
                            let orderResponse = try JSONDecoder().decode(EventbriteOrderResponse.self, from: data!)
                            DispatchQueue.main.async {
                                let dict = orderResponse.orders.reduce(into: [String: Bool](), { $0["eventbrite_\($1.event.id)"] = true })
                                self.writeEventbriteEventIds(eventIds: dict) { error, _ in completion(error) }
                            }
                        } catch {
                            completion(error)
                        }
                    }
                }
                requestAPI.resume()
            }
        })
    }
    
    private func writeEventbriteEventIds(eventIds: [String: Bool], completion: @escaping (Error?, DatabaseReference) -> Void) {
        getEventbriteEventIdsReference()?.setValue(eventIds, withCompletionBlock: completion)
    }
    
    private func transformEventIdsToEvents(dataSnapshot: DataSnapshot, source: Event.Source) -> Observable<[Event]> {
        let arrayOfObservables = dataSnapshot.children.reduce(into: [Observable<Event?>](), { (observables, childSnapshot) in
            if let childSnapshot = childSnapshot as? DataSnapshot,
                let eventId = getEventIdFromDataSnapshot(dataSnapshot: childSnapshot, source: source) {
                let event = EventRepository.shared.get(eventId: eventId).startWith(nil).map({ e -> Event? in
                    e?.source = source
                    return e
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
            .map({ $0.flatMap{ $0 } as [Event] })
    }
    
    func activateEvent(event: Event, completion: @escaping ((Error?, DatabaseReference) -> Void)) {
        getActiveEventsInfoReference()?.child(event.id).setValue(event.rsvpStatus, withCompletionBlock: completion)
    }
    
    func deactivateEvent(event: Event, completion: @escaping ((Error?, DatabaseReference) -> Void)) {
        getActiveEventsInfoReference()?.child(event.id).removeValue(completionBlock: completion)
    }
}
