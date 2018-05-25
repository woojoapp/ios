//
//  PreferencesViewModel.swift
//  Woojo
//
//  Created by Edouard Goossens on 13/05/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import RxCocoa
import RxSwift
import Promises

class PreferencesViewModel {
    private var preferences: Driver<Preferences?>
    
    init() {
        self.preferences = UserRepository.shared.getPreferences().asDriver(onErrorJustReturn: nil)
    }
    
    private(set) lazy var gender: Driver<Preferences.Gender?> = {
        return preferences.map { $0?.gender }
    }()
    
    private(set) lazy var ageRange: Driver<Preferences.AgeRange?> = {
        return preferences.map { $0?.ageRange }
    }()
    
    func setPreferences(preferences: Preferences) -> Promise<Void> {
        return UserRepository.shared.setPreferences(preferences: preferences)
    }
}
