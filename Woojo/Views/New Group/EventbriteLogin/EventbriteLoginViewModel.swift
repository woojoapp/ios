//
//  EventbriteLoginViewModel.swift
//  Woojo
//
//  Created by Edouard Goossens on 23/05/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import Promises

class EventbriteLoginViewModel {
    func setEventbriteAccessToken(accessToken: String) -> Promise<Void> {
        return UserEventbriteIntegrationRepository.shared.setEventbriteAccessToken(accessToken: accessToken)
    }
    
    func syncEventbriteEvents() -> Promise<Void> {
        return UserEventbriteIntegrationRepository.shared.syncEventbriteEvents()
    }
}
