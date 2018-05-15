//
// Created by Edouard Goossens on 10/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import RxSwift
import Promises

class UserProfileRepository: BaseRepository {
    static let shared = UserProfileRepository()
    
    override private init() {
        super.init()
    }

    func getProfileReference(uid: String) -> DatabaseReference {
        return firebaseDatabase.reference().child("users").child(uid).child("profile")
    }

    func getProfile(uid: String) -> Observable<User.Profile?> {
        return withCurrentUser { _ in
            return self.getProfileReference(uid: uid)
                .rx_observeEvent(event: .value)
                .map{ User.Profile(from: $0) }
        }
    }

    func getProfile() -> Observable<User.Profile?> {
        return withCurrentUser {
            $0.child("profile")
                .rx_observeEvent(event: .value)
                .map{
                    let profile = User.Profile(dataSnapshot: $0)
                    print("UUSER", $0.key, profile?.photoIds)
                    return profile
                }
        }
    }

    func setProfile(profile: User.Profile) -> Promise<Void> {
        return doWithCurrentUser { $0.child("profile").setValuePromise(value: profile.dictionary) }
    }

    func setDescription(description: String) -> Promise<Void> {
        return doWithCurrentUser { $0.child("profile/description").setValuePromise(value: description) }
    }

    func getPhotoStorageReference(pictureId: String, size: User.Profile.Photo.Size) -> Observable<StorageReference> {
        return getCurrentUserStorageReference().map {
            $0.child("profile/photos")
                .child(pictureId)
                .child(size.rawValue)
        }
    }
    
    func getPhotoStorageReferenceSnapshot(uid: String, pictureId: String, size: User.Profile.Photo.Size) -> StorageReference {
        return firebaseStorage.reference().child("users").child(uid).child("profile/photos").child(pictureId).child(size.rawValue)
    }

    func getPhoto(position: Int, size: User.Profile.Photo.Size) -> Observable<StorageReference?> {
        return withCurrentUser { ref -> Observable<StorageReference?> in
            ref.child("profile")
                .child("photos")
                .child(String(position))
                .rx_observeEvent(event: .value)
                .map { $0.value as? String }
                .concatMap { pictureId -> Observable<StorageReference?> in
                    if let pictureId = pictureId {
                        return self.getPhotoStorageReference(pictureId: pictureId, size: size).map { $0 as StorageReference? }
                    }
                    return Observable.of(nil)
                }
        }
    }
    
    func getPhotoAsImage(position: Int, size: User.Profile.Photo.Size) -> Observable<UIImage?> {
        return getPhoto(position: position, size: size).flatMap { photo -> Observable<UIImage?> in
            if let photo = photo {
                return Observable.create { observer -> Disposable in
                    UIImageView().sd_setImage(with: photo, placeholderImage: nil, completion: { image, error, _, _ in
                        if let error = error {
                            observer.on(.error(error))
                        } else {
                            observer.on(.next(image))
                            observer.on(.completed)
                        }
                    })
                    return Disposables.create()
                }
            }
            return Observable.just(nil)
        }
    }

    func getPhotos(size: User.Profile.Photo.Size) -> Observable<[Int: StorageReference]> {
        return withCurrentUser { ref in
            return ref.child("profile")
                .child("photos")
                .rx_observeEvent(event: .value).map { dataSnapshot in
                    var photos = [Int: StorageReference]()
                    for childSnapshot in dataSnapshot.children.allObjects as! [DataSnapshot] {
                        if let position = Int(childSnapshot.key),
                           let pictureId = childSnapshot.value as? String {
                            photos[position] = self.getPhotoStorageReferenceSnapshot(uid: ref.key, pictureId: pictureId, size: size)
                        }
                    }
                    return photos
                }
        }
    }

    func setPhoto(data: Data, position: Int) -> Promise<String> {
        return uploadPicture(data: data, size: .full).then { generatedPictureId -> Promise<String> in
            if let squareThumbnailSide = User.Profile.Photo.sizes[.thumbnail] {
                let targetSize = CGSize(width: squareThumbnailSide, height: squareThumbnailSide)
                if let thumbnailData = self.resizePicture(data: data, targetSize: targetSize) {
                    return self.uploadPicture(data: thumbnailData, size: .thumbnail, pictureId: generatedPictureId)
                }
                return Promise(UserProfileRepositoryError.pictureResizeFailed)
            }
            return Promise(UserProfileRepositoryError.pictureResizeFailed)
        }.then { generatedPictureId -> Promise<String> in
            return self.setPhotoId(position: position, pictureId: generatedPictureId).then { _ in return generatedPictureId }
        }
    }

    func setPhotoId(position: Int, pictureId: String) -> Promise<Void> {
        return doWithCurrentUser { $0.child("profile/photos").child(String(position)).setValuePromise(value: pictureId) }
    }

    func setPhotoIds(photoIds: [Int: String]) -> Promise<Void> {
        let dictionary = photoIds.reduce(into: [String: String]()) { (result: inout [String: String], tuple: (key: Int, value: String)) in
            result[String(tuple.key)] = tuple.value
        }
        return doWithCurrentUser { $0.child("profile/photos").setValuePromise(value: dictionary) }
    }

    private func resizePicture(data: Data, targetSize: CGSize) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
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
        if let newImage = newImage { return UIImagePNGRepresentation(newImage) }
        return nil
    }

    private func uploadPicture(data: Data, size: User.Profile.Photo.Size, pictureId: String = UUID().uuidString) -> Promise<String> {
        return getPhotoStorageReference(pictureId: pictureId, size: size).toPromise().then { ref in
            return ref.putDataPromise(uploadData: data)
        }.then { _ in return pictureId }
    }

    func removePhoto(position: Int) -> Promise<Void> {
        return deleteFiles(forPhotoAt: position).then {
            return self.removePhotoId(position: position)
        }
    }

    private func removePhotoId(position: Int) -> Promise<Void> {
        return doWithCurrentUser { $0.child("profile/photos").child(String(position)).removeValuePromise() }
    }

    private func deleteFiles(forPhotoAt position: Int) -> Promise<Void> {
        return doWithCurrentUser { ref in
            return ref.child("profile/photos").child(String(position)).getDataSnapshot()
        }.then { dataSnapshot in
            if let id = dataSnapshot.value as? String {
                return self.doWithCurrentUserStorage { $0.child("profile/photos").child(id).child("full").deletePromise() }
            } else {
                return Promise(UserProfileRepositoryError.noPhotoIdAtGivenPosition)
            }
        }
    }

    func setOccupation(occupation: String) -> Promise<Void> {
        return doWithCurrentUser { $0.child("profile/occupation").setValuePromise(value: occupation) }
    }

    enum UserProfileRepositoryError: Error {
        case pictureResizeFailed
        case noPhotoIdAtGivenPosition
    }
}
