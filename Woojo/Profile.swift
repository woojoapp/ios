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
import FacebookCore
import RxSwift
import RxCocoa
import Applozic

extension User {
 
    class Profile {
        
        // MARK: - Properties
        
        var displayName: String?
        var photoID: String?
        var gender: Gender?
        var birthday: Date?
        var description: String?
        var city: String?
        var country: String?
        var user: User
        var photo: Variable<UIImage> = Variable(#imageLiteral(resourceName: "placeholder_40x40"))
        var age: Int {
            get {
                print(birthday)
                return Calendar.current.dateComponents([Calendar.Component.year], from: birthday!, to: Date()).year!
            }
        }
        
        var isObserved = false
        var birthdayFormatter: DateFormatter = {
            let birthdayFormatter = DateFormatter()
            birthdayFormatter.dateFormat = "MM/dd/yyyy"
            return birthdayFormatter
        }()
        
        var ref: FIRDatabaseReference? {
            get {
                return user.ref.child(Constants.User.Profile.firebaseNode)
            }
        }
        
        var storageRef: FIRStorageReference? {
            get {
                return user.storageRef.child(Constants.User.Profile.firebaseNode)
            }
        }
        
        init(for user: User) {
            self.user = user
        }
        
        // MARK: - Methods
        
        func generatePhotoDownloadURL(completion: @escaping (URL?, Error?) -> Void) {
            if let photoID = photoID {
                storageRef?.child(Constants.User.Profile.Photo.firebaseNode).child(photoID).downloadURL(completion: completion)
            }
        }
        
        func loadFrom(firebase snapshot: FIRDataSnapshot) {
            if let value = snapshot.value as? [String:Any] {
                displayName = value[Constants.User.Profile.properties.firebaseNodes.firstName] as? String
                photoID = value[Constants.User.Profile.properties.firebaseNodes.photoID] as? String
                // Download and cache profile photo only for the current user
                if self.user is CurrentUser {
                    generatePhotoDownloadURL { downloadURL, error in
                        SDWebImageManager.shared().downloadImage(with: downloadURL, options: [], progress: nil, completed: { image, _, _, _, _ in
                            if let image = image {
                                self.photo.value = image
                            }
                        })
                    }
                }
                if let genderString = value[Constants.User.Profile.properties.firebaseNodes.gender] as? String {
                    gender = Gender(rawValue: genderString)
                }
                description = value[Constants.User.Profile.properties.firebaseNodes.description] as? String
                city = value[Constants.User.Profile.properties.firebaseNodes.city] as? String
                country = value[Constants.User.Profile.properties.firebaseNodes.country] as? String
                if let birthdayString = value[Constants.User.Profile.properties.firebaseNodes.birthday] as? String {
                    birthday = birthdayFormatter.date(from: birthdayString)
                }
            } else {
                print("Failed to create Profile from Firebase snapshot.", snapshot)
            }
        }
        
        func loadFrom(graphAPI dict: [String:Any]?) {
            if let dict = dict {
                displayName = dict[Constants.User.Profile.properties.graphAPIKeys.firstName] as? String
                if let genderString = dict[Constants.User.Profile.properties.graphAPIKeys.gender] as? String {
                    gender = Gender(rawValue: genderString)
                }
                /*if let ageRangeDict = dict[Constants.User.Profile.properties.graphAPIKeys.ageRange] as? [String:Any] {
                    ageRange = (ageRangeDict[Constants.User.Profile.properties.graphAPIKeys.ageRangeMin] as? Int, ageRangeDict[Constants.User.Profile.properties.graphAPIKeys.ageRangeMax] as? Int)
                }*/
                if let birthdayString = dict[Constants.User.Profile.properties.graphAPIKeys.birthday] as? String {
                    birthday = birthdayFormatter.date(from: birthdayString)
                }
            } else {
                print("Failed to create Profile from Graph API dictionary.", dict as Any)
            }
        }
        
        func loadFromFirebase(completion: ((Profile?, Error?) -> Void)? = nil) {
            ref?.observeSingleEvent(of: .value, with: { snapshot in
                self.loadFrom(firebase: snapshot)
                completion?(self, nil)
            }, withCancel: { error in
                print("Failed to load profile from Firebase: \(error.localizedDescription)")
                completion?(self, error)
            })
        }
        
        func toDictionary() -> [String:Any] {
            var dict: [String:Any] = [:]
            dict[Constants.User.Profile.properties.firebaseNodes.firstName] = self.displayName
            dict[Constants.User.Profile.properties.firebaseNodes.photoID] = self.photoID
            dict[Constants.User.Profile.properties.firebaseNodes.gender] = self.gender?.rawValue
            if let birthday = birthday {
                dict[Constants.User.Profile.properties.firebaseNodes.birthday] = birthdayFormatter.string(from: birthday)
            }
            dict[Constants.User.Profile.properties.firebaseNodes.description] = self.description
            dict[Constants.User.Profile.properties.firebaseNodes.city] = self.city
            dict[Constants.User.Profile.properties.firebaseNodes.country] = self.country
            return dict
        }
        
        func startObserving() {
            isObserved = true
            ref?.observe(.value, with: { snapshot in
                self.loadFrom(firebase: snapshot)
            }, withCancel: { error in
                print("Failed to observe profile: \(error.localizedDescription)")
                self.isObserved = false
            })
        }
        
        func stopObserving() {
            ref?.removeAllObservers()
            isObserved = false
        }
        
        func updateFromFacebook(completion: ((Error?) -> Void)?) {
            User.Profile.GraphRequest(profile: self)?.start { response, result in
                switch result {
                case.success(let response):
                    // Update Firebase with the data loaded from Facebook
                    self.displayName = response.profile?.displayName
                    if let responseAsDictionary = response.profile?.toDictionary() {
                        self.ref?.updateChildValues(responseAsDictionary) { error, _ in
                            if let error = error {
                                print("Failed to update user profile in database: \(error)")
                            }
                            completion?(error)
                        }
                        self.ref?.child(Constants.User.Properties.fbAppScopedID).setValue(response.fbAppScopedID)
                    }
                case .failed(let error):
                    print("UserProfileGraphRequest failed: \(error.localizedDescription) \(AccessToken.current)")
                    completion?(error)
                }
            }
        }
        
        func updatePhotoFromFacebook(completion: ((Error?) -> Void)?) {
            User.Profile.PhotoGraphRequest(profile: self)?.start { response, result in
                switch result {
                case .success(let response):
                    if let photoID = response.photoID {
                        self.ref?.child(Constants.User.Profile.properties.firebaseNodes.photoID).setValue(photoID)
                        if let photoURL = response.photoURL {
                            let photoRef = self.storageRef?.child(Constants.User.Profile.Photo.firebaseNode).child(photoID)
                            DispatchQueue.global().async {
                                do {
                                    photoRef?.put(try Data(contentsOf: photoURL), metadata: nil) { metadata, error in
                                        if let error = error {
                                            print("Failed to upload profile photo to Firebase Storage: \(error)")
                                        } else {
                                            if let thumbnailURL = response.thumbnailURL {
                                                let thumbnailRef = self.storageRef?.child(Constants.User.Profile.Thumbnail.firebaseNode).child(photoID)
                                                DispatchQueue.global().async {
                                                    do {
                                                        thumbnailRef?.put(try Data(contentsOf: thumbnailURL), metadata: nil) { metadata, error in
                                                            if let error = error {
                                                                print("Failed to upload profile photo thumbnail to Firebase Storage: \(error)")
                                                            }
                                                            completion?(error)
                                                        }
                                                    } catch {
                                                        print("Failed to download profile photo thumbnail from Facebook: \(error)")
                                                        completion?(error)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                } catch {
                                    print("Failed to download profile photo from Facebook: \(error)")
                                    completion?(error)
                                }
                            }
                        }
                    }
                case .failed(let error):
                    print("UserProfilePhotoGraphRequest failed: \(error.localizedDescription)")
                    completion?(error)
                }
            }
        }
        
    }
    
}

// MARK: - Graph requests

extension User.Profile {
    
    struct GraphRequest: GraphRequestProtocol {
        
        struct Response: GraphResponseProtocol {
            
            init(rawResponse: Any?) {
                self.rawResponse = rawResponse
                if let rawResponse = rawResponse as? [String:Any] {
                    profile = User.Profile(for: User(uid: "_"))
                    profile.loadFrom(graphAPI: rawResponse)
                    fbAppScopedID = rawResponse["id"] as? String
                }
            }
            
            var rawResponse: Any?
            var profile: User.Profile!
            var fbAppScopedID: String?
            
        }
        
        init?(profile: User.Profile) {
            if let fbAppScopedID = profile.user.fbAppScopedID {
                self.fbAppScopedID = fbAppScopedID
            } else {
                print("Failed to initialize User.Profile.GraphRequest from profile. Missing FB app scoped ID.", profile)
                return nil
            }
            if let fbAccessToken = profile.user.fbAccessToken {
                self.accessToken = fbAccessToken
            } else {
                print("Failed to initialize User.Profile.GraphRequest from profile. Missing FB access token.", profile)
                return nil
            }
            self.profile = profile
        }
        
        var profile: User.Profile
        var fbAppScopedID: String
        var accessToken: AccessToken?
        var graphPath: String {
            get {
                return "/\(fbAppScopedID)"
            }
        }
        var parameters: [String: Any]? = {
            let fields = [Constants.GraphRequest.UserProfile.fieldID,
                          Constants.User.Profile.properties.graphAPIKeys.firstName,
                          Constants.User.Profile.properties.graphAPIKeys.birthday,
                          Constants.User.Profile.properties.graphAPIKeys.gender]
            return [Constants.GraphRequest.fields:fields.joined(separator: Constants.GraphRequest.fieldsSeparator)]
        }()
        var httpMethod: GraphRequestHTTPMethod = .GET
        var apiVersion: GraphAPIVersion = .defaultVersion
        
    }
    
    struct PhotoGraphRequest: GraphRequestProtocol {
        
        struct Response: GraphResponseProtocol {
            
            init(rawResponse: Any?) {
                self.rawResponse = rawResponse
                if let dict = rawResponse as? [String:Any] {
                    let albums = dict[Constants.GraphRequest.UserProfilePhoto.keys.data] as! NSArray
                    for album in albums {
                        if let album = album as? [String:Any] {
                            if let albumType = album[Constants.GraphRequest.UserProfilePhoto.keys.type] as? String {
                                if albumType == Constants.GraphRequest.UserProfilePhoto.keys.typeProfile {
                                    if let albumCover = album[Constants.GraphRequest.UserProfilePhoto.keys.coverPhoto] as? [String:Any] {
                                        if let url = albumCover[Constants.GraphRequest.UserProfilePhoto.keys.coverPhotoSource] as? String {
                                            self.photoURL = URL(string: url)
                                        }
                                        if let id = albumCover[Constants.GraphRequest.UserProfilePhoto.keys.coverPhotoID] as? String {
                                            self.photoID = id
                                        }
                                    }
                                    if let picture = album[Constants.GraphRequest.UserProfilePhoto.keys.picture] as? [String:Any] {
                                        if let pictureData = picture[Constants.GraphRequest.UserProfilePhoto.keys.pictureData] as? [String:Any] {
                                            if let url = pictureData[Constants.GraphRequest.UserProfilePhoto.keys.pictureDataURL] as? String {
                                                self.thumbnailURL = URL(string: url)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            var rawResponse: Any?
            var photoURL: URL?
            var photoID: String?
            var thumbnailURL: URL?
            
        }
        
        init?(profile: User.Profile) {
            if let fbAppScopedID = profile.user.fbAppScopedID {
                self.fbAppScopedID = fbAppScopedID
            } else {
                print("Failed to initialize User.Profile.PhotoGraphRequest from profile. Missing FB app scoped ID.", profile)
                return nil
            }
            if let fbAccessToken = profile.user.fbAccessToken {
                self.fbAccessToken = fbAccessToken
            } else {
                print("Failed to initialize User.Profile.PhotoGraphRequest from profile. Missing FB access token.", profile)
                return nil
            }
        }
        
        var fbAppScopedID: String
        var fbAccessToken: AccessToken?
        var graphPath: String {
            get {
                return "/\(fbAppScopedID)/\(Constants.GraphRequest.UserProfilePhoto.path)"
            }
        }
        var parameters: [String:Any]? = [Constants.GraphRequest.fields:Constants.GraphRequest.UserProfilePhoto.fields]
        var accessToken: AccessToken? = AccessToken.current
        var httpMethod: GraphRequestHTTPMethod = .GET
        var apiVersion: GraphAPIVersion = .defaultVersion
        
    }
}
