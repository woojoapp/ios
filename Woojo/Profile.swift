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

extension User {
 
    class Profile {
        
        // MARK: - Properties
        
        var displayName: String?
        var photoID: String?
        var gender: Gender?
        var birthday: Date?
        var description: Variable<String> = Variable("")
        var city: String?
        var country: String?
        var user: User
        var photos: Variable<[Photo?]> = Variable([nil, nil, nil, nil, nil, nil])
        var age: Int {
            get {
                if let birthday = birthday {
                    return Calendar.current.dateComponents([Calendar.Component.year], from: birthday, to: Date()).year!
                } else {
                    return 0
                }
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
        
        func loadFrom(firebase snapshot: FIRDataSnapshot) {
            if let value = snapshot.value as? [String:Any] {
                displayName = value[Constants.User.Profile.properties.firebaseNodes.firstName] as? String
                let photosSnap = snapshot.childSnapshot(forPath: Constants.User.Profile.Photo.firebaseNode)
                for item in photosSnap.children {
                    print(item)
                    if let photoSnap = item as? FIRDataSnapshot, let index = Int(photoSnap.key), let id = photoSnap.value as? String {
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
                print(description.value)
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
                dict[Constants.User.Profile.properties.firebaseNodes.birthday] = birthdayFormatter.string(from: birthday)
            }
            if self.description.value != "" {
                dict[Constants.User.Profile.properties.firebaseNodes.description] = self.description.value
            }
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
        
        func setDescription(description: String, completion: ((Error?) -> Void)? = nil) {
            ref?.child(Constants.User.Profile.properties.firebaseNodes.description).setValue(description, withCompletionBlock: { error, ref in
                if let error = error {
                    print("Failed to save user profile description: \(error.localizedDescription)")
                }
                completion?(error)
            })
        }
        
        func updateFromFacebook(completion: ((Error?) -> Void)?) {
            User.Profile.GraphRequest(profile: self)?.start { response, result in
                switch result {
                case.success(let response):
                    // Update Firebase with the data loaded from Facebook
                    self.displayName = response.profile?.displayName
                    if let responseAsDictionary = response.profile?.toDictionary() {
                        print(responseAsDictionary)
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
                        //self.ref?.child(Constants.User.Profile.properties.firebaseNodes.photoID).setValue(photoID)
                        if let photoURL = response.photoURL {
                            DispatchQueue.global().async {
                                do {
                                    let data = try Data(contentsOf: photoURL)
                                    if let image = UIImage(data: data) {
                                        self.setPhoto(photo: image, id: photoID, index: 0) { _, error in
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
                    }
                case .failed(let error):
                    print("UserProfilePhotoGraphRequest failed: \(error.localizedDescription)")
                    completion?(error)
                }
            }
        }
        
        func set(photo: Photo, at index: Int, completion: ((Error?) -> Void)? = nil) {
            Woojo.User.current.value?.profile.photos.value[index] = photo
            ref?.child(Constants.User.Profile.Photo.firebaseNode).child(String(index)).setValue(photo.id, withCompletionBlock: { error, ref in
                completion?(error)
            })
        }
        
        func remove(photoAt index: Int, completion: ((Error?) -> Void)? = nil) {
            self.ref?.child(Constants.User.Profile.Photo.firebaseNode).child(String(index)).removeValue(completionBlock: { error, ref in
                completion?(error)
            })
        }
        
        func deleteFiles(forPhotoAt index: Int, completion: ((Error?) -> Void)? = nil) {
            Woojo.User.current.value?.profile.photos.value[index] = nil
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
        }
        
        
    }
    
}

extension User.Profile {
    
    class Photo {
        
        init?(profile: User.Profile?, index: Int, id: String) {
            if let profile = profile {
                self.profile = profile
                self.index = index
                self.id = id
            } else {
                return nil
            }
        }
        
        var profile: User.Profile
        var images: [Size:UIImage] = [:]
        var index: Int
        var id: String
        
        enum Size: Int {
            case thumbnail = 100
            case full = 414
        }
        
        func generatePhotoDownloadURL(size: Size, completion: @escaping (URL?, Error?) -> Void) {
            let path: String
            switch size {
            case .thumbnail:
                path = Constants.User.Profile.Photo.properties.thumbnail
            default:
                path = Constants.User.Profile.Photo.properties.full
            }
            profile.storageRef?.child(Constants.User.Profile.Photo.firebaseNode).child(id).child(path).downloadURL(completion: completion)
        }
        
        func download(size: Size, completion: (() -> Void)? = nil) {
            generatePhotoDownloadURL(size: size) { url, error in
                SDWebImageManager.shared().downloadImage(with: url, options: [], progress: nil, completed: { image, _, _, _, _ in
                    if let image = image {
                        self.images[size] = image
                        completion?()
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
        
    }
    
    func downloadAllPhotos(size: User.Profile.Photo.Size) {
        for photo in self.photos.value {
            photo?.download(size: size)
        }
    }
    
    fileprivate func resize(image: UIImage, targetSize: CGSize) -> UIImage? {
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
    }
    
    func setPhoto(photo: UIImage, id: String, index: Int, completion: ((Photo?, Error?) -> Void)? = nil) {
        // Resize image to the maximum size we'll need
        let group = DispatchGroup()
        
        group.enter()
        guard let fullImage = resize(image: photo, targetSize: CGSize(width: User.Profile.Photo.Size.full.rawValue, height: User.Profile.Photo.Size.full.rawValue)), let fullImageJPEGData = UIImageJPEGRepresentation(fullImage, 0.9) else {
            print("Failed to resize photo to full size")
            return
        }
        storageRef?.child(Constants.User.Profile.Photo.firebaseNode).child(id).child(Constants.User.Profile.Photo.properties.full).put(fullImageJPEGData, metadata: nil, completion: { _, error in
            if let error = error {
                print("Failed to store full size photo: \(error.localizedDescription)")
                completion?(nil, error)
            }
            group.leave()
        })
        
        group.enter()
        guard let thumbnailImage = resize(image: photo, targetSize: CGSize(width: User.Profile.Photo.Size.thumbnail.rawValue, height: User.Profile.Photo.Size.thumbnail.rawValue)), let thumbnailImageJPEGData = UIImageJPEGRepresentation(thumbnailImage, 0.9) else {
            print("Failed to resize photo to thumbnail size")
            return
        }
        storageRef?.child(Constants.User.Profile.Photo.firebaseNode).child(id).child(Constants.User.Profile.Photo.properties.thumbnail).put(thumbnailImageJPEGData, metadata: nil, completion: { _, error in
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
