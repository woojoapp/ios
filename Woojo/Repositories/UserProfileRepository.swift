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
    
    func getProfileReference(uid: String) -> DatabaseReference {
        return firebaseDatabase.reference().child("users").child(uid).child("profile")
    }

    func getProfile(uid: String) -> Observable<User.Profile?> {
        return UserRepository.shared.getUser(uid: uid).map { $0?.profile }
    }

    func getProfile() -> Observable<User.Profile?> {
        return UserRepository.shared.getUser().map { $0?.profile }
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
        return withCurrentUser { self.getPhoto(uid: $0.key, position: position, size: size) }
    }

    func getPhoto(uid: String, position: Int, size: User.Profile.Photo.Size) -> Observable<StorageReference?> {
        /* return withCurrentUser { ref -> Observable<StorageReference?> in
            self.getUserDatabaseReference(uid: uid)
                .child("profile")
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
        } */
        return getPhotos(uid: uid, size: size).map { $0?[position] }
    }
    
    func getPhotoAsImage(position: Int, size: User.Profile.Photo.Size) -> Observable<UIImage?> {
        return withCurrentUser { self.getPhotoAsImage(uid: $0.key, position: position, size: size) }
    }
    
    func getPhotoAsImage(uid: String, position: Int, size: User.Profile.Photo.Size) -> Observable<UIImage?> {
        return getPhoto(uid: uid, position: position, size: size).flatMap { photo -> Observable<UIImage?> in
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
    
    func getPhotosAsImages(uid: String, size: User.Profile.Photo.Size) -> Observable<[Int: UIImage]?> {
        return getPhotos(uid: uid, size: size).map { photos -> [Int: UIImage]? in
            if let photos = photos {
                var images = [Int: UIImage]()
                for (index, photo) in photos {
                    UIImageView().sd_setImage(with: photo, placeholderImage: nil, completion: { image, error, _, _ in
                        if error != nil {
                            images[index] = image
                        }
                    })
                }
                return images
            }
            return nil
        }
    }

    func getPhotos(size: User.Profile.Photo.Size) -> Observable<[Int: StorageReference]?> {
        return withCurrentUser { self.getPhotos(uid: $0.key, size: size) }
    }
    
    func getPhotos(uid: String, size: User.Profile.Photo.Size) -> Observable<[Int: StorageReference]?> {
        return getProfile(uid: uid).map { $0?.photoIds?.mapValues { self.getPhotoStorageReferenceSnapshot(uid: uid, pictureId: $0, size: size) } }
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
        return deleteFiles(forPhotoAt: position).then { _ in
            return self.removePhotoId(position: position)
        }
    }

    func removePhotoId(position: Int) -> Promise<Void> {
        return doWithCurrentUser { $0.child("profile/photos").child(String(position)).removeValuePromise() }
    }

    func deleteFiles(forPhotoAt position: Int) -> Promise<Void> {
        return doWithCurrentUser { ref in
            return ref.child("profile/photos").child(String(position)).getDataSnapshot()
        }.then { dataSnapshot -> Promise<Void> in
            if let id = dataSnapshot.value as? String {
                let full: Promise<Void> = self.doWithCurrentUserStorage { $0.child("profile/photos").child(id).child("full").deletePromise() }
                let thumbnail: Promise<Void> = self.doWithCurrentUserStorage { $0.child("profile/photos").child(id).child("thumbnail").deletePromise() }
                let result: Promise<[Void]> = all(full, thumbnail)
                return result.then { _ in return Void() }
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
