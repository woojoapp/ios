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
import SDWebImage
import FirebaseStorageUI

/* class Profile: Codable {

    // MARK: - Properties
    var uid: String?
    var firstName: String?
    var birthday: Date?
    var gender: String?
    var description: String?
    var location: Location?
    var occupation: String?
    var photoIds: [String: String] = [:]

    //var photos: Variable<[Photo?]> = Variable([nil, nil, nil, nil, nil, nil])

    private enum CodingKeys: String, CodingKey {
        case uid, gender, birthday, description, location, occupation
        case firstName = "first_name"
        case photoIds = "photos"
    }

    class Photo {
        enum Size: String {
            case thumbnail
            case full
        }

        static let sizes = [Size.thumbnail: 200, Size.full: 414]
        static let aspectRatio = Float(1.6)
        static let ppp = 3
    }

} */
        
        /* var photoCount: Int {
            get {
                return photoIds.count
            }
        }
        var age: Int {
            get {
                if let birthday = birthday {
                    return Calendar.current.dateComponents([Calendar.Component.year], from: birthday, to: Date()).year!
                } else {
                    return 0
                }
            }
        }

        var displaySummary: String {
            get {
                if let displayName = firstName {
                    return "\(displayName), \(age)"
                } else {
                    return "User, \(age)"
                }
            }
        } */
        
        /* var occupations: [String] {
            get {
                let occupationObjects = education.map{$0.school?.name} + work.map{$0.displayString}
                return occupationObjects.flatMap{$0}
            }
        } */

        /* var birthdayFacebookFormatter: DateFormatter = {
            let birthdayFormatter = DateFormatter()
            birthdayFormatter.dateFormat = "MM/dd/yyyy"
            return birthdayFormatter
        }()
        
        var birthdayFirebaseFormatter: DateFormatter = {
            let birthdayFormatter = DateFormatter()
            birthdayFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZ"
            return birthdayFormatter
        }()
        
        var ref: DatabaseReference? {
            get {
                return Database.database().reference().child("users").child(uid!).child("profile")
            }
        }
        
        var storageRef: StorageReference? {
            get {
                return Storage.storage().reference().child("users").child(uid!).child("profile")
            }
        } */

        // MARK: - Methods
        
        /* static func from(dataSnapshot: DataSnapshot) -> Profile {
            let profile = Profile()
            profile.loadFrom(firebase: dataSnapshot)
            return profile
        }
        
        func loadFrom(firebase snapshot: DataSnapshot) {
            if let value = snapshot.value as? [String:Any] {
                displayName = value[Constants.User.Profile.properties.firebaseNodes.firstName] as? String
                firstName.value = value[Constants.User.Profile.properties.firebaseNodes.firstName] as? String ?? ""
                let photosSnap = snapshot.childSnapshot(forPath: Constants.User.Profile.Photo.firebaseNode)
                for item in photosSnap.children {
                    if let photoSnap = item as? DataSnapshot, let index = Int(photoSnap.key), let id = photoSnap.value as? String {
                        let photo = Photo(profile: self, index: index, id: id)
                        // Download and cache profile photo only
                        if index == 0 {
                            photo?.download(size: .full)
                        }
                        self.photos.value[index] = photo
                    }
                }
                if let genderString = value[Constants.User.Profile.properties.firebaseNodes.gender] as? String {
                    gender = Gender(rawValue: genderString)
                }
                description.value = value[Constants.User.Profile.properties.firebaseNodes.description] as? String ?? ""
                occupation.value = value["occupation"] as? String ?? ""
                do {
                    location = try Location(from: value["location"])
                    work = try [Work](from: value["work"]) ?? []
                    education = try [Education](from: value["education"]) ?? []
                } catch(let error) {
                    print("Failed to create Profile from Firebase snapshot.", snapshot, error)
                }
                if let birthdayString = value[Constants.User.Profile.properties.firebaseNodes.birthday] as? String {
                    if let birthday = birthdayFirebaseFormatter.date(from: birthdayString) {
                        self.birthday = birthday
                    } else if let birthday = birthdayFacebookFormatter.date(from: birthdayString) {
                        self.birthday = birthday
                    }
                }
            } else {
                print("Failed to create Profile from Firebase snapshot.", snapshot)
            }
        }
        
        func loadFrom(graphAPI dict: [String:Any]?) {
            do {
                if let dict = dict {
                    displayName = dict[Constants.User.Profile.properties.graphAPIKeys.firstName] as? String
                    if let genderString = dict[Constants.User.Profile.properties.graphAPIKeys.gender] as? String {
                        gender = Gender(rawValue: genderString)
                    }
                    if let birthdayString = dict[Constants.User.Profile.properties.graphAPIKeys.birthday] as? String {
                        birthday = birthdayFacebookFormatter.date(from: birthdayString)
                    }
                    if let location = dict["location"] as? [String:Any] {
                        self.location = try Location(from: location["location"])
                    }
                    work = try [Work](from: dict["work"]) ?? []
                    education = try [Education](from: dict["education"]) ?? []
                } else {
                    print("Failed to create Profile from Graph API dictionary.", dict as Any)
                }
            } catch(let error) {
                print("Failed to create Profile from Graph API dictionary.", dict as Any, error)
            }
        }
        
        func loadFromFirebase(completion: ((Profile?, Error?) -> Void)? = nil) {
            print("CANDIDATE ADDED ici")
            ref?.observeSingleEvent(of: .value, with: { snapshot in
                print("CANDIDATE ADDED", snapshot)
                self.loadFrom(firebase: snapshot)
                completion?(self, nil)
            }, withCancel: { error in
                print("Failed to load profile from Firebase: \(error.localizedDescription)")
                completion?(self, error)
            })
        }
        
        func startObservingPhotos() {
            ref?.child(Constants.User.Profile.Photo.firebaseNode).child("0").observe(.value, with: { snapshot in
                if let photoID = snapshot.value as? String,
                    let photo = Photo(profile: self, index: 0, id: photoID) {
                    photo.download() {
                        self.photos.value[0] = photo
                    }
                }
            })
            ref?.child(Constants.User.Profile.Photo.firebaseNode).observe(.childAdded, with: { snapshot in
                if let photoID = snapshot.value as? String,
                    let photoIndex = Int(snapshot.key),
                    let photo = Photo(profile: self, index: photoIndex, id: photoID) {
                    photo.download() {
                        self.photos.value[photoIndex] = photo
                    }
                }
            }, withCancel: { error in
                print("Cancelled observing childAdded for profile photos: \(error.localizedDescription)")
            })
            ref?.child(Constants.User.Profile.Photo.firebaseNode).observe(.childRemoved, with: { snapshot in
                if let photoIndex = Int(snapshot.key) {
                    self.photos.value[photoIndex] = nil
                }
            }, withCancel: { error in
                print("Cancelled observing childRemoved for profile photos: \(error.localizedDescription)")
            })
        }
        
        func stopObservingPhotos() {
            ref?.child(Constants.User.Profile.Photo.firebaseNode).removeAllObservers()
            ref?.child(Constants.User.Profile.Photo.firebaseNode).child("0").removeAllObservers()
        }
        
        func toDictionary() -> [String:Any] {
            var dict: [String:Any] = [:]
            dict[Constants.User.Profile.properties.firebaseNodes.firstName] = self.displayName
            dict[Constants.User.Profile.properties.firebaseNodes.photoID] = self.photoID
            dict[Constants.User.Profile.properties.firebaseNodes.gender] = self.gender?.rawValue
            if let birthday = birthday {
                dict[Constants.User.Profile.properties.firebaseNodes.birthday] = birthdayFirebaseFormatter.string(from: birthday)
            }
            if self.description.value != "" {
                dict[Constants.User.Profile.properties.firebaseNodes.description] = self.description.value
            }
            //dict[Constants.User.Profile.properties.firebaseNodes.city] = self.city
            // dict[Constants.User.Profile.properties.firebaseNodes.country] = self.country
            dict["location"] = location.dictionary
            dict["work"] = work.array
            dict["education"] = education.array
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
        
        func setDescription(description: String, completion: ((Error?) -> Void)? = nil) {
            ref?.child(Constants.User.Profile.properties.firebaseNodes.description).setValue(description, withCompletionBlock: { error, ref in
                if let error = error {
                    print("Failed to save user profile description: \(error.localizedDescription)")
                }
                completion?(error)
            })
        }
        
        func setOccupation(occupation: String, completion: ((Error?) -> Void)? = nil) {
            ref?.child("occupation").setValue(occupation, withCompletionBlock: { error, ref in
                if let error = error {
                    print("Failed to save user profile occupation: \(error.localizedDescription)")
                }
                completion?(error)
            })
        }
        
        func setDefaultOccupation() {
            if work.count > 0 {
                setOccupation(occupation: work[0].displayString)
            } else if education.count > 0 {
                if let school = education[education.count - 1].school?.name {
                    setOccupation(occupation: school)
                }
            }
        } */
        
        /* func updateFromFacebook(completion: ((Error?) -> Void)?) {
            User.Profile.GraphRequest(profile: self)?.start { response, result in
                switch result {
                case .success(let response):
                    // Update Firebase with the data loaded from Facebook
                    self.firstName = response.profile?.firstName
                    if let responseAsDictionary = response.profile.dictionary {
                        print(responseAsDictionary)
                        self.ref?.updateChildValues(responseAsDictionary) { error, _ in
                            if let error = error {
                                print("Failed to update user profile in database: \(error)")
                            }
                            if let firstName = response.profile?.displayName {
                                Analytics.setUserProperties(properties: ["first_name": firstName])
                            }
                            if let gender = response.profile?.gender {
                                Analytics.setUserProperties(properties: ["gender": gender.rawValue])
                            }
                            if let birthDate = response.profile?.birthday {
                                let birthDateString = self.birthdayFirebaseFormatter.string(from: birthDate)
                                Analytics.setUserProperties(properties: ["birth_date": birthDateString])
                            }
                            completion?(error)
                        }
                        self.ref?.child(Constants.User.Properties.fbAppScopedID).setValue(response.fbAppScopedID)
                        if let fbAppScopedId = response.fbAppScopedID {
                            Analytics.setUserProperties(properties: ["facebook_app_scoped_id": fbAppScopedId])
                        }
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
                    //if let photoID =  {
                        if let photoURL = response.photoURL {
                            DispatchQueue.global().async {
                                do {
                                    let data = try Data(contentsOf: photoURL)
                                    if let image = UIImage(data: data) {
                                        self.setPhoto(photo: image, id: UUID().uuidString, index: 0) { _, error in
                                            completion?(error)
                                        }
                                    } else {
                                        completion?(nil)
                                    }
                                } catch {
                                    print("Failed to download profile photo from Facebook: \(error)")
                                    completion?(error)
                                }
                            }
                        }
                    //}
                case .failed(let error):
                    print("UserProfilePhotoGraphRequest failed: \(error.localizedDescription)")
                    completion?(error)
                }
            }
        } */
        
        /* func set(photo: Photo, at index: Int, completion: ((Error?) -> Void)? = nil) {
            User.current.value?.profile.photos.value[index] = photo
            ref?.child(Constants.User.Profile.Photo.firebaseNode).child(String(index)).setValue(photo.id, withCompletionBlock: { error, ref in
                completion?(error)
            })
        }
        
        func remove(photoAt index: Int, completion: ((Error?) -> Void)? = nil) {
            self.ref?.child(Constants.User.Profile.Photo.firebaseNode).child(String(index)).removeValue(completionBlock: { error, ref in
                completion?(error)
            })
        } */
        
        /*func deleteFiles(forPhotoAt index: Int, completion: ((Error?) -> Void)? = nil) {
            User.current.value?.profile?.photos.value[index] = nil
            ref?.child(Constants.User.Profile.Photo.firebaseNode).child(String(index)).observeSingleEvent(of: .value, with: { snapshot in
                if let id = snapshot.value as? String {
                    self.storageRef?.child(Constants.User.Profile.Photo.firebaseNode).child(id).child(Constants.User.Profile.Photo.properties.full).delete { error in
                        if let error = error {
                            print("Failed to delete photo file: \(error.localizedDescription)")
                        }
                        self.storageRef?.child(Constants.User.Profile.Photo.firebaseNode).child(id).child(Constants.User.Profile.Photo.properties.thumbnail).delete { error in
                            if let error = error {
                                print("Failed to delete photo file: \(error.localizedDescription)")
                            }
                            completion?(error)
                        }
                    }
                }
            })
        }*/


    /* class Photo {
        var index: Int
        var id: String
        
        var refs: [Size:StorageReference?] {
            get {
                return [.thumbnail:profile.storageRef?.child(Constants.User.Profile.Photo.firebaseNode).child(self.id).child(Constants.User.Profile.Photo.properties.thumbnail),
                        .full:profile.storageRef?.child(Constants.User.Profile.Photo.firebaseNode).child(id).child(Constants.User.Profile.Photo.properties.full)]
            }
        }
        
        enum Size: String {
            case thumbnail
            case full
        }

        static let sizes = [Size.thumbnail: 200, Size.full: 414]
        static let aspectRatio = Float(1.6)
        static let ppp = 3
        
        /* func generatePhotoDownloadURL(size: Size, completion: @escaping (URL?, Error?) -> Void) {
            let path: String
            switch size {
            case .thumbnail:
                path = Constants.User.Profile.Photo.properties.thumbnail
            default:
                path = Constants.User.Profile.Photo.properties.full
            }
            profile.storageRef?.child(Constants.User.Profile.Photo.firebaseNode).child(id).child(path).downloadURL(completion: completion)
        } */
        
        func download(size: Size, completion: (() -> Void)? = nil) {
            if let s = refs[size],
                let storageRef = s {
                UIImageView().sd_setImage(with: storageRef, placeholderImage: #imageLiteral(resourceName: "placeholder_40x40"), completion: { image, error, cacheType, ref in
                    if error == nil {
                        self.images[size] = image
                        completion?()
                    } else {
                        print("Error downloading image \(storageRef): \(error)")
                    }
                })
            }
        }
        
        func download(completion: (() -> Void)? = nil) {
            let group = DispatchGroup()
            group.enter()
            download(size: .full, completion: {
                group.leave()
            })
            group.enter()
            download(size: .thumbnail, completion: {
                group.leave()
            })
            group.notify(queue: .main) {
                completion?()
            }
        }
        
        func removeImageFromCache(size: Size) {
            if let s = refs[size], let storageRef = s {
                SDImageCache.shared().removeImage(forKey: storageRef.fullPath)
            }
        }
        
        func removeFromCache() {
            removeImageFromCache(size: .thumbnail)
            removeImageFromCache(size: .full)
        }
        
    }
    
    func downloadAllPhotos(size: User.Profile.Photo.Size, completion: (() -> Void)? = nil) {
        let group = DispatchGroup()
        for photo in self.photos.value {
            if let photo = photo {
                group.enter()
                photo.download(size: size) {
                    group.leave()
                }
            }
        }
        group.notify(queue: .main) {
            completion?()
        }
    }
    
    func removeAllPhotosFromCache() {
        for photo in photos.value {
            photo?.removeFromCache()
        }
    } */
    
    /* fileprivate func resize(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    } */
    
    /* func setPhoto(photo: UIImage, id: String, index: Int, completion: ((Photo?, Error?) -> Void)? = nil) {
        // Resize image to the maximum size we'll need
        let group = DispatchGroup()
        group.enter()
        let aspectRatio = 1.6
        let ppp = 3.0
        guard let fullImage = resize(image: photo, targetSize: CGSize(width: Double(User.Profile.Photo.Size.full.rawValue) * ppp, height: Double(User.Profile.Photo.Size.full.rawValue) * aspectRatio * ppp)), let fullImageJPEGData = UIImageJPEGRepresentation(fullImage, 0.9) else {
            print("Failed to resize photo to full size")
            return
        }
        storageRef?.child(Constants.User.Profile.Photo.firebaseNode).child(id).child(Constants.User.Profile.Photo.properties.full).putData(fullImageJPEGData, metadata: nil, completion: { _, error in
            if let error = error {
                print("Failed to store full size photo: \(error.localizedDescription)")
                completion?(nil, error)
            }
            group.leave()
        })
        
        group.enter()
        guard let thumbnailImage = resize(image: photo, targetSize: CGSize(width: Double(User.Profile.Photo.Size.thumbnail.rawValue) * ppp, height: Double(User.Profile.Photo.Size.thumbnail.rawValue) * ppp)), let thumbnailImageJPEGData = UIImageJPEGRepresentation(thumbnailImage, 0.9) else {
            print("Failed to resize photo to thumbnail size")
            return
        }
        storageRef?.child(Constants.User.Profile.Photo.firebaseNode).child(id).child(Constants.User.Profile.Photo.properties.thumbnail).putData(thumbnailImageJPEGData, metadata: nil, completion: { _, error in
            if let error = error {
                print("Failed to store photo thumbnail: \(error.localizedDescription)")
                completion?(nil, error)
            }
            group.leave()
        })
        
        group.notify(queue: DispatchQueue.main, execute: {
            self.ref?.child(Constants.User.Profile.Photo.firebaseNode).child(String(index)).setValue(id, withCompletionBlock: { error, ref in
                if let error = error {
                    print("Failed to set full size photo id: \(error.localizedDescription)")
                    completion?(nil, error)
                }
                if let photo = Photo(profile: self, index: index, id: id) {
                    photo.images[User.Profile.Photo.Size.full] = fullImage
                    photo.images[User.Profile.Photo.Size.thumbnail] = thumbnailImage
                    self.photos.value[index] = photo
                    completion?(photo, nil)
                } else {
                    completion?(nil, nil)
                }
            })
        })
        
    }
    
}*/

// MARK: - Graph requests

/* extension User.Profile {
    
    struct PhotoGraphRequest: GraphRequestProtocol {
        
        struct Response: GraphResponseProtocol {
            
            init(rawResponse: Any?) {
                self.rawResponse = rawResponse
                if let dict = rawResponse as? [String:Any],
                    let picture = dict[Constants.GraphRequest.UserProfilePhoto.keys.picture] as? [String:Any],
                    let data = picture[Constants.GraphRequest.UserProfilePhoto.keys.data] as? [String:Any],
                    let url = data[Constants.GraphRequest.UserProfilePhoto.keys.url] as? String {
                        self.photoURL = URL(string: url)
                }
            }
            
            var rawResponse: Any?
            var photoURL: URL?
            var thumbnailURL: URL?
            
        }
        
        init?(profile: User.Profile) {
            if let fbAppScopedID = profile.user?.fbAppScopedID {
                self.fbAppScopedID = fbAppScopedID
            } else {
                print("Failed to initialize User.Profile.PhotoFullGraphRequest from profile. Missing FB app scoped ID.", profile)
                return nil
            }
            if let fbAccessToken = profile.user?.fbAccessToken {
                self.fbAccessToken = fbAccessToken
            } else {
                print("Failed to initialize User.Profile.PhotoFullGraphRequest from profile. Missing FB access token.", profile)
                return nil
            }
        }
        
        var fbAppScopedID: String
        var fbAccessToken: AccessToken?
        var graphPath: String {
            get {
                return fbAppScopedID
            }
        }
        var parameters: [String:Any]? = [Constants.GraphRequest.fields:Constants.GraphRequest.UserProfilePhoto.fields]
        var accessToken: AccessToken? = AccessToken.current
        var httpMethod: GraphRequestHTTPMethod = .GET
        var apiVersion: GraphAPIVersion = .defaultVersion
        
    }
    
    class Work: Codable {
        var employer: Employer?
        var position: Position?
        var displayString: String {
            get {
                var positionString = ""
                if let positionName = position?.name {
                    positionString = "\(positionName) - "
                }
                return "\(positionString)\(employer?.name ?? "")"
            }
        }
        class Employer: Codable {
            var name: String?
        }
        class Position: Codable {
            var name: String?
        }
    }
    class Education: Codable {
        var school: School?
        class School: Codable {
            var name: String?
        }
    }
} */
