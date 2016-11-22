//
//  Profile.swift
//  Woojo
//
//  Created by Edouard Goossens on 20/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage

struct Profile {
    
    var displayName: String?
    var photoID: String?
    var gender: Gender?
    var ageRange: (min: Int?, max: Int?)
    var description: String?
    var city: String?
    var country: String?
    var user: User?
    
    func photoDownloadURL(completion: @escaping (URL?, Error?) -> Void) {
        if let user = user, let uid = user.uid, let photoID = photoID {
            FIRStorage.storage().reference().child(Constants.User.firebaseNode).child(uid).child(Constants.User.Profile.firebaseNode).child(Constants.User.Profile.Photo.firebaseNode).child(photoID).downloadURL(completion: completion)
        }
    }
    
}

extension Profile {

    static func from(firebase snapshot: FIRDataSnapshot) -> Profile? {
        if let value = snapshot.value as? [String:Any] {
            var profile = Profile()
            profile.displayName = value[Constants.User.Profile.properties.firebaseNodes.firstName] as? String
            profile.photoID = value[Constants.User.Profile.properties.firebaseNodes.photoID] as? String
            if let genderString = value[Constants.User.Profile.properties.firebaseNodes.gender] as? String {
                profile.gender = Gender(rawValue: genderString)
            }
            profile.description = value[Constants.User.Profile.properties.firebaseNodes.description] as? String
            profile.city = value[Constants.User.Profile.properties.firebaseNodes.city] as? String
            profile.country = value[Constants.User.Profile.properties.firebaseNodes.country] as? String
            return profile
        } else {
            print("Failed to create Profile from Firebase snapshot.", snapshot)
            return nil
        }
    }
    
    static func from(graphAPI dict: [String:Any]?) -> Profile? {
        if let dict = dict {
            var profile = Profile()
            profile.displayName = dict[Constants.User.Profile.properties.graphAPIKeys.firstName] as? String
            if let gender = dict[Constants.User.Profile.properties.graphAPIKeys.gender] as? String {
                profile.gender = Gender(rawValue: gender)
            }
            if let ageRange = dict[Constants.User.Profile.properties.graphAPIKeys.ageRange] as? [String:Any] {
                profile.ageRange = (ageRange[Constants.User.Profile.properties.graphAPIKeys.ageRangeMin] as? Int, ageRange[Constants.User.Profile.properties.graphAPIKeys.ageRangeMax] as? Int)
            }
            return profile
        } else {
            print("Failed to create Profile from Graph API dictionary.", dict as Any)
            return nil
        }
    }
    
    static func get(for uid: String, completion: @escaping (Profile?) -> Void) {
        FIRDatabase.database().reference().child(Constants.User.firebaseNode).child(uid).child(Constants.User.Profile.firebaseNode).observeSingleEvent(of: .value, with: { snapshot in
            completion(from(firebase: snapshot))
        })
    }
    
    func toDictionary() -> [String:Any] {
        var dict: [String:Any] = [:]
        dict[Constants.User.Profile.properties.firebaseNodes.firstName] = self.displayName
        dict[Constants.User.Profile.properties.firebaseNodes.photoID] = self.photoID
        dict[Constants.User.Profile.properties.firebaseNodes.gender] = self.gender?.rawValue
        dict[Constants.User.Profile.properties.firebaseNodes.ageRange] = [Constants.User.Profile.properties.firebaseNodes.ageRangeMin:self.ageRange.min,
                                                                          Constants.User.Profile.properties.firebaseNodes.ageRangeMax:self.ageRange.max]
        dict[Constants.User.Profile.properties.firebaseNodes.description] = self.description
        dict[Constants.User.Profile.properties.firebaseNodes.city] = self.city
        dict[Constants.User.Profile.properties.firebaseNodes.country] = self.country
        return dict
    }

}
