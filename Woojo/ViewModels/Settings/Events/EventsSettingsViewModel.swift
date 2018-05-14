//
//  EventsSettingsViewModel.swift
//  Woojo
//
//  Created by Edouard Goossens on 13/05/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import RxSwift
import Promises

class EventsSettingsViewModel {
    
    func isEventbriteIntegrated() -> Observable<Bool> {
        return UserEventbriteIntegrationRepository.shared.isEventbriteIntegrated()
    }
    
    func isFacebookIntegrated() -> Observable<Bool> {
        return UserFacebookIntegrationRepository.shared.isFacebookIntegrated()
    }
    
    func removeEventbriteIntegration() -> Promise<Void> {
        return UserEventbriteIntegrationRepository.shared.removeEventbriteIntegration()
    }
    
}
