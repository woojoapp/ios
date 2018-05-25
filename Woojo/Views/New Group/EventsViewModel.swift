//
// Created by Edouard Goossens on 10/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import RxCocoa
import RxSwift
import Promises

class EventsViewModel {
    static let shared = EventsViewModel()

    private(set) lazy var events: Driver<[User.Event]> = {
        let facebookEvents = UserFacebookIntegrationRepository.shared.getFacebookEvents().startWith([])
        let eventbriteEvents = UserEventbriteIntegrationRepository.shared.getEventbriteEvents().startWith([])
        let recommendedEvents = UserRecommendedEventsRepository.shared.getRecommendedEvents().startWith([])
        let sponsoredEvents = UserSponsoredEventsRepository.shared.getSponsoredEvents().startWith([])
        let activeEventsInfo = UserActiveEventRepository.shared.getActiveEventsInfo()
        var events = Observable.combineLatest(facebookEvents, eventbriteEvents, recommendedEvents, sponsoredEvents) { fb, ev, re, sp -> [User.Event] in
            return Array(Set(fb + ev + re + sp)) // Remove duplicates, priority is FB -> EV -> RE -> SP?
        }
        events = Observable.combineLatest(events, activeEventsInfo) { evs, dataSnapshot -> [User.Event] in
            for ev in evs {
                if let eventId = ev.event.id {
                    ev.active = dataSnapshot.hasChild(eventId)
                }
            }
            return evs
        }
        return events.asDriver(onErrorJustReturn: [])
    }()

    private(set) lazy var isEventbriteIntegrated: Driver<Bool> = {
        return UserEventbriteIntegrationRepository.shared
            .getEventbriteAccessToken()
            .map { $0 != nil }
            .asDriver(onErrorJustReturn: false)
    }()

    private(set) lazy var isFacebookIntegrated: Driver<Bool> = {
        return UserFacebookIntegrationRepository.shared
            .isFacebookIntegrated()
            .asDriver(onErrorJustReturn: false)
    }()

    func syncEventbriteEvents() -> Promise<Void> {
        return UserEventbriteIntegrationRepository.shared.syncEventbriteEvents()
    }
    
    func syncFacebookEvents(viewController: UIViewController, loginIfNecessary: Bool = true) -> Promise<Void> {
        return UserFacebookIntegrationRepository.shared.syncFacebookEvents(viewController: viewController, loginIfNecessary: loginIfNecessary)
    }

    func activateEvent(eventId: String) -> Promise<Void> {
        return UserActiveEventRepository.shared.activateEvent(eventId: eventId)
    }

    func deactivateEvent(eventId: String) -> Promise<Void> {
        return UserActiveEventRepository.shared.deactivateEvent(eventId: eventId)
    }
}
