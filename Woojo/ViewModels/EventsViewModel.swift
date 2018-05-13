//
// Created by Edouard Goossens on 10/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import RxSwift
import Promises

class EventsViewModel {
    static let shared = EventsViewModel()

    private init() {}

    func getEvents() -> Observable<[Event]> {
        let facebookEvents = UserFacebookIntegrationRepository.shared.getFacebookEvents().startWith([])
        let eventbriteEvents = UserEventbriteIntegrationRepository.shared.getEventbriteEvents().startWith([])
        let recommendedEvents = UserRecommendedEventsRepository.shared.getRecommendedEvents().startWith([])
        let sponsoredEvents = UserSponsoredEventsRepository.shared.getSponsoredEvents().startWith([])
        let activeEventsInfo = UserActiveEventRepository.shared.getActiveEventsInfo()
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

    func isEventbriteIntegrated() -> Observable<Bool> {
        return UserEventbriteIntegrationRepository.shared
                .getEventbriteAccessToken()
                .map { $0 != nil }
    }

    func isFacebookIntegrated() -> Observable<Bool> {
        return UserFacebookIntegrationRepository.shared
                .getFacebookAccessToken()
                .map { $0 != nil }
    }

    func syncEventbriteEvents() -> Promise<Void> {
        return UserEventbriteIntegrationRepository.shared
                .syncEventbriteEvents()
    }

    func activateEvent(event: Event) -> Promise<Void> {
        return UserActiveEventRepository.shared.activateEvent(event: event)
    }

    func deactivateEvent(event: Event) -> Promise<Void> {
        return UserActiveEventRepository.shared.deactivateEvent(event: event)
    }
}
