//
// Created by Edouard Goossens on 12/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import FirebaseStorage
import Foundation
import RxSwift
import RxCocoa
import Promises

class ProfileViewModel {
    private static let agePlaceHolder = 0
    static let shared = ProfileViewModel()
    
    private var user: Driver<User?>
    
    private(set) lazy var uid: Driver<String?> = {
        return user.map { $0?.uid }.asDriver(onErrorJustReturn: nil)
    }()
    
    init() {
        self.user = UserRepository.shared.getUser().asDriver(onErrorJustReturn: nil)
    }

    private(set) lazy var nameAge: Driver<String?> = {
        [unowned self] in
        return user.map {
            var components = [String]()
            if let firstName = $0?.profile?.firstName {
                components.append(firstName)
            }
            if let age = $0?.profile?.getAge() {
                components.append(String(age))
            }
            return components.joined(separator: ", ")
        }
    }()
    
    private(set) lazy var city: Driver<String?> = {
        [unowned self] in
        return user.map { $0?.profile?.location?.city }
    }()
    
    private(set) lazy var occupation: Driver<String?> = {
        [unowned self] in
        return user.map { $0?.profile?.occupation }
    }()
    
    private(set) lazy var description: Driver<String?> = {
        [unowned self] in
        return user.map { $0?.profile?.description }
    }()
    
    private(set) lazy var thumbnails: Driver<[Int: StorageReference]?> = {
        return UserProfileRepository.shared.getPhotos(size: .thumbnail).asDriver(onErrorJustReturn: nil)
    }()

    func setDescription(description: String) -> Promise<Void> {
        return UserProfileRepository.shared.setDescription(description: description)
    }

    func setOccupation(occupation: String) -> Promise<Void> {
        return UserProfileRepository.shared.setOccupation(occupation: occupation)
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

    /* func setPhotoIds(photos: [Int: StorageReference]) -> Promise<Void> {
        let photoIds = photos.mapValues { $0.parent()!.name }
        return UserProfileRepository.shared.setPhotoIds(photoIds: photoIds)
    } */
    
    func setPhotoId(position: Int, pictureId: String) -> Promise<Void> {
        return UserProfileRepository.shared.setPhotoId(position: position, pictureId: pictureId)
    }
    
    func removePhotoId(position: Int) -> Promise<Void> {
        return UserProfileRepository.shared.removePhotoId(position: position)
    }

}
