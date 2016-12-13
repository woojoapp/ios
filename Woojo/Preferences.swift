//
//  Preferences.swift
//  Woojo
//
//  Created by Edouard Goossens on 06/12/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import FirebaseDatabase

extension CurrentUser {
    
    class Preferences {
        
        enum Gender: String {
            case male
            case female
            case all
        }
        
        var gender: Gender
        var ageRange: (min: Int, max: Int)
        
        var ref: FIRDatabaseReference {
            get {
                return User.current.value!.ref.child(Constants.User.Preferences.firebaseNode)
            }
        }
        
        init(gender: Gender, ageRange: (min: Int, max: Int)) {
            self.gender = gender
            self.ageRange = ageRange
        }
        
        func loadFrom(firebase snapshot: FIRDataSnapshot) {
            if let value = snapshot.value as? [String:Any] {
                if let genderString = value[Constants.User.Preferences.properties.firebaseNodes.gender] as? String {
                    self.gender = Gender(rawValue: genderString)!
                }
                if let ageRange = value[Constants.User.Preferences.properties.firebaseNodes.ageRange] as? [String:Any],
                    let min = ageRange[Constants.User.Preferences.properties.firebaseNodes.ageRangeMin] as? Int,
                    let max = ageRange[Constants.User.Preferences.properties.firebaseNodes.ageRangeMax] as? Int {
                    self.ageRange = (min: min, max: max)
                }
            }
        }
        
        func loadFromFirebase(completion: ((Preferences?, Error?) -> Void)? = nil) {
            ref.observeSingleEvent(of: .value, with: { snapshot in
                self.loadFrom(firebase: snapshot)
                completion?(self, nil)
            }, withCancel: { error in
                print("Failed to load preferences from Firebase: \(error.localizedDescription)")
                completion?(self, error)
            })
        }
        
        // TODO: Move values to Constants file or Firebase Remote Config
        func setDefaults() {
            if let profile = User.current.value?.profile, let gender = profile.gender {
                var dmin = 2
                var dmax = 8
                switch gender {
                case .female:
                    self.gender = .male
                case .male:
                    self.gender = .female
                    dmin = 8
                    dmax = 2
                }
                self.ageRange = (min: max(profile.age - dmin, 18), max: min(profile.age + dmax, 60))
            } else {
                print("Failed to set default preferences")
            }
        }
        
        func toDictionary() -> [String:Any] {
            var dict: [String:Any] = [:]
            dict[Constants.User.Preferences.properties.firebaseNodes.ageRange] = [
                Constants.User.Preferences.properties.firebaseNodes.ageRangeMin: self.ageRange.min,
                Constants.User.Preferences.properties.firebaseNodes.ageRangeMax: self.ageRange.max
            ]
            dict[Constants.User.Preferences.properties.firebaseNodes.gender] = self.gender.rawValue
            return dict
        }
        
        func save(completion: ((Error?) -> Void)? = nil) {
            ref.setValue(toDictionary(), withCompletionBlock: { error, ref in
                completion?(error)
            })
        }
        
    }
    
}
