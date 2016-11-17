//
//  User.swift
//  Woojo
//
//  Created by Edouard Goossens on 14/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//
//  Represents the currently authenticated user of the app.
//  Data should be kept in sync between Facebook, Firebase and this class.
//

import Foundation
import Firebase
import Atlas
import FacebookCore

class CurrentUser {
    
    static var uid: String {
        get {
            return (FIRAuth.auth()?.currentUser?.uid)!
        }
    }
    
    static var ref: FIRDatabaseReference {
        get {
            return FIRDatabase.database().reference().child("users").child(uid)
        }
    }
    
    static var firebaseAuthUser: FIRUser? {
        get {
            return FIRAuth.auth()?.currentUser
        }
    }
    
    static var storageRef: FIRStorageReference {
        get {
            return FIRStorage.storage().reference().child("users").child(uid)
        }
    }
    
    struct Profile {
        
        var displayName: String? {
            get {
                return FIRAuth.auth()?.currentUser?.displayName
            }
        }
        var photoURL: URL? {
            get {
                return FIRAuth.auth()?.currentUser?.photoURL
            }
        }
        var gender: Gender?
        var ageRange: (min: Int, max: Int)?
        var description: String?
        var city: String?
        var country: String?
        var photoID: String?
        
        static var ref: FIRDatabaseReference {
            get {
                return CurrentUser.ref.child("profile")
            }
        }
        
        static var storageRef: FIRStorageReference {
            get {
                return CurrentUser.storageRef.child("profile")
            }
        }
        
        static func loadDataFromFacebook() {
            if let user = firebaseAuthUser {
                let userProfileGraphRequest = UserProfileGraphRequest()
                userProfileGraphRequest.start { response, result in
                    switch result {
                    case.success(let response):
                        // Update Firebase with the data loaded from Facebook
                        let profileChangeRequest = user.profileChangeRequest()
                        if let firstName = response.firstName {
                            profileChangeRequest.displayName = firstName
                        }
                        profileChangeRequest.commitChanges { (error) in
                            if let error = error {
                                print("Failed to update Firebase user profile display name: \(error.localizedDescription)")
                            }
                        }
                        if let responseAsDictionary = response.dictionaryValue {
                            ref.updateChildValues(responseAsDictionary) { error, _ in
                                if let error = error {
                                    print("Failed to update user profile in database: \(error)")
                                }
                            }
                        }
                    case .failed(let error):
                        print("UserProfileGraphRequest failed: \(error.localizedDescription)")
                    }
                }
                
            } else {
                print("Failed to load profile data from Facebook: No authenticated Firebase user.")
            }
        }
        
        static func loadPhotoFromFacebook() {
            if let user = firebaseAuthUser {
                let userProfilePhotoGraphRequest = UserProfilePhotoGraphRequest()
                userProfilePhotoGraphRequest.start { response, result in
                    switch result {
                    case .success(let response):
                        print("Photo URL: \(response.photoURL?.absoluteString)")
                        print("Thumbnail URL: \(response.thumbnailURL?.absoluteString)")
                        if let photoID = response.photoID {
                            if let photoURL = response.photoURL {
                                let photoRef = storageRef.child("photos").child(photoID)
                                DispatchQueue.global().async {
                                    photoRef.put(try! Data(contentsOf: photoURL), metadata: nil) { metadata, error in
                                        if let error = error {
                                            print("Failed to upload profile photo to Firebase Storage: \(error)")
                                        }
                                    }
                                }
                            }
                            if let thumbnailURL = response.thumbnailURL {
                                let thumbnailRef = storageRef.child("thumbnails").child(photoID)
                                DispatchQueue.global().async {
                                    thumbnailRef.put(try! Data(contentsOf: thumbnailURL), metadata: nil) { metadata, error in
                                        if let error = error {
                                            print("Failed to upload profile photo to Firebase Storage: \(error)")
                                        } else {
                                            ref.child("photoID").setValue(photoID)
                                            if let metadata = metadata, let downloadURL = metadata.downloadURL() {
                                                let profileChangeRequest = user.profileChangeRequest()
                                                profileChangeRequest.photoURL = downloadURL
                                                profileChangeRequest.commitChanges { error in
                                                    if let error = error {
                                                        print("Failed to update Firebase user profile photo URL: \(error.localizedDescription)")
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                        }                        
                    case .failed(let error):
                        print("UserProfileGraphRequest failed: \(error.localizedDescription)")
                    }
                }
            } else {
                print("Failed to load profile data from Facebook: No authenticated Firebase user.")
            }
        }
        
    }

    
}

/*extension User {
    static let firebasePath = "users"
    static let dateFormatter: DateFormatter = {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
        return formatter
    }() 
    
    static func from(snapshot: FIRDataSnapshot) -> User? {
        let value = snapshot.value as! [String:Any]
        
        let testUser = User()
        testUser.userID = snapshot.key
        
        guard let account = value["account"] as? [String:Any] else {
            print("Can't create a user without account data.")
            return nil
        }
        
        guard let profile = account["profile"] as? [String:Any] else {
            print("Can't create a user without account profile data.")
            return nil
        }
        
        testUser.avatarImageURL = URL(string: profile["profileImageURL"] as! String)
        
        guard let cachedUserProfile = profile["cachedUserProfile"] as? [String:Any] else {
            print("Can't create a user without account profile cachedUserProfile data.")
            return nil
        }
        
        testUser.firstName = cachedUserProfile["first_name"] as! String
        testUser.lastName = cachedUserProfile["last_name"] as! String
        testUser.gender = Gender(rawValue: cachedUserProfile["gender"] as! String)!
        
        return testUser
    }
    
    static func get(by uid: String, completion: @escaping (User) -> Void) {
        FIRDatabase.database().reference().child(User.firebasePath).child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            if let user = User.from(snapshot: snapshot) {
                completion(user)
            } else {
                print("Failed to get user with uid \(uid)")
            }
        })
    }
    
    func toAny() -> Any {
        let any = [String:Any]()
        
        return any
    }
}*/
