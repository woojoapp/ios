//
// Created by Edouard Goossens on 12/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import FirebaseStorage
import Foundation
import RxSwift
import Promises

class ProfileViewModel {
    static let shared = ProfileViewModel()
    private static let agePlaceHolder = 0

    private init() {}

    func getNameAge() -> Observable<String> {
        return UserProfileRepository.shared.getProfile()
                .map { profile in
                    var components: [String] = []
                    if let firstName = profile?.firstName { components.append(firstName) }
                    if let age = profile?.getAge() { components.append(String(age)) }
                    return components.joined(separator: ", ")
                }
    }

    func getCity() -> Observable<String?> {
        return UserProfileRepository.shared.getProfile().map { $0?.location?.city }
    }

    func getOccupation() -> Observable<String?> {
        return UserProfileRepository.shared.getProfile().map { $0?.occupation }
    }

    func getDescription() -> Observable<String?> {
        return UserProfileRepository.shared.getProfile().map { $0?.description }
    }

    func setDescription(description: String) -> Promise<Void> {
        return UserProfileRepository.shared.setDescription(description: description)
    }

    func setOccupation(occupation: String) -> Promise<Void> {
        return UserProfileRepository.shared.setOccupation(occupation: occupation)
    }

    func getPhotos(size: User.Profile.Photo.Size) -> Observable<[Int: StorageReference]> {
        return UserProfileRepository.shared.getPhotos(size: size)
    }

    func removePhoto(position: Int) -> Promise<Void> {
        return UserProfileRepository.shared.removePhoto(position: position)
    }

    func setPhoto(position: Int, photo: StorageReference) -> Promise<Void> {
        return UserProfileRepository.shared.setPhotoId(position: position, pictureId: photo.parent()!.name)
    }

    func setPhoto(position: Int, data: Data) -> Promise<String> {
        return UserProfileRepository.shared.setPhoto(data: data, position: position)
    }

    func setPhotoIds(photos: [Int: StorageReference]) -> Promise<Void> {
        let photoIds = photos.mapValues { $0.parent()!.name }
        return UserProfileRepository.shared.setPhotoIds(photoIds: photoIds)
    }

}
