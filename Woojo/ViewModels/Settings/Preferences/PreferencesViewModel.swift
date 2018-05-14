//
//  PreferencesViewModel.swift
//  Woojo
//
//  Created by Edouard Goossens on 13/05/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import RxSwift
import Promises

class PreferencesViewModel {
    func getGender() -> Observable<Preferences.Gender?> {
        return UserRepository.shared.getPreferences().map { $0?.gender }
    }
    
    func getAgeRange() -> Observable<Preferences.AgeRange?> {
        return UserRepository.shared.getPreferences().map { $0?.ageRange }
    }
    
    func setPreferences(preferences: Preferences) -> Promise<Void> {
        return UserRepository.shared.setPreferences(preferences: preferences)
    }
}
