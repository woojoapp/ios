//
//  EventsSettingsViewModel.swift
//  Woojo
//
//  Created by Edouard Goossens on 13/05/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import RxCocoa
import RxSwift
import Promises

class EventsSettingsViewModel {
    
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
    
    func removeEventbriteIntegration() -> Promise<Void> {
        return UserEventbriteIntegrationRepository.shared.removeEventbriteIntegration()
    }
    
}
