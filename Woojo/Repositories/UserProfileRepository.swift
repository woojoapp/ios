//
// Created by Edouard Goossens on 10/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import RxSwift
import Promises

class UserProfileRepository {
    private let firebaseAuth = Auth.auth()
    private let firebaseDatabase = Database.database()
    private let firebaseStorage = Storage.storage()

    static let shared = UserProfileRepository()
    private init() {}

    private func getUid() -> String { return firebaseAuth.currentUser!.uid }

    private func getUserDatabaseReference(uid: String) -> DatabaseReference {
        return firebaseDatabase
                .reference()
                .child("users")
                .child(uid)
    }

    private func getCurrentUserDatabaseReference() -> DatabaseReference {
        return getUserDatabaseReference(uid: getUid())
    }

    private func getUserStorageReference(uid: String) -> StorageReference {
        return firebaseStorage
                .reference()
                .child("users")
                .child(uid)
    }

    private func getCurrentUserStorageReference() -> StorageReference {
        return getUserStorageReference(uid: getUid())
    }

    func getProfileReference(uid: String) -> DatabaseReference {
        return firebaseDatabase.reference().child("users").child(uid).child("profile")
    }

    func getProfile(uid: String?) -> Observable<User.Profile?> {
        return getProfileReference(uid: getUid())
                .rx_observeEvent(event: .value)
                .map{ try User.Profile(from: $0) }
    }

    func getProfile() -> Observable<User.Profile?> {
        return getProfile(uid: getUid())
    }

    func setProfile(profile: User.Profile) -> Promise<Void> {
        return getCurrentUserDatabaseReference().child("profile").setValuePromise(value: profile.dictionary)
    }

    func setDescription(description: String) -> Promise<Void> {
        return getCurrentUserDatabaseReference().child("profile/description").setValuePromise(value: description)
    }

    func setPhoto(data: Data, position: Int) -> Promise<Void> {
        return uploadPicture(data: data, size: .full).then { generatedPictureId -> Promise<String> in
            if let squareThumbnailSide = User.Profile.Photo.sizes[.thumbnail] {
                let targetSize = CGSize(width: squareThumbnailSide, height: squareThumbnailSide)
                if let thumbnailData = self.resizePicture(data: data, targetSize: targetSize) {
                    return self.uploadPicture(data: thumbnailData, size: .thumbnail, pictureId: generatedPictureId)
                }
                return Promise(UserProfileRepositoryError.pictureResizeFailed)
            }
            return Promise(UserProfileRepositoryError.pictureResizeFailed)
        }.then { generatedPictureId -> Promise<Void> in
            return self.setPhotoId(id: generatedPictureId, position: position)
        }
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

    private func setPhotoId(id: String, position: Int) -> Promise<Void> {
        return getCurrentUserDatabaseReference()?.child("profile/photos").child(String(position)).setValuePromise(value: id)
    }

    private func uploadPicture(data: Data, size: User.Profile.Photo.Size, pictureId: String = UUID().uuidString) -> Promise<String> {
        return getCurrentUserStorageReference()
                .child("profile/photos")
                .child(pictureId)
                .child(size.rawValue)
                .putDataPromise(uploadData: data).then { _ in return pictureId }
    }

    func removePhoto(position: Int) -> Promise<Void> {
        return deleteFiles(forPhotoAt: position).then {
            return self.removePhotoId(position: position)
        }
    }

    private func removePhotoId(position: Int) -> Promise<Void> {
        return getCurrentUserDatabaseReference().child("profile/photos").child(String(position)).removeValuePromise()
    }

    private func deleteFiles(forPhotoAt position: Int) -> Promise<Void> {
        return getCurrentUserDatabaseReference().child("profile/photos").child(String(position)).getDataSnapshot().then { dataSnapshot in
            if let id = dataSnapshot.value as? String {
                return self.getCurrentUserStorageReference().child("profile/photos").child(id).child("full").deletePromise()
            } else {
                return Promise(UserProfileRepositoryError.noPhotoIdAtGivenPosition)
            }
        }
    }

    enum UserProfileRepositoryError: Error {
        case pictureResizeFailed
        case noPhotoIdAtGivenPosition
    }
}
