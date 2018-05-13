//
// Created by Edouard Goossens on 11/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import Branch
import FirebaseAuth
import FirebaseStorage
import RxSwift


class SettingsViewModel {
    static let shared = SettingsViewModel()

    private init() {}

    func getFullMainUserProfilePicture() -> Observable<StorageReference?> {
        return UserProfileRepository.shared.getPhoto(position: 0, size: .full)
    }

    func getUserFirstName() -> Observable<String?> {
        return UserProfileRepository.shared.getProfile().map { $0?.firstName }
    }

    func getUserShortDescription() -> Observable<String> {
        return UserProfileRepository.shared.getProfile().map {
            var description = ""
            if let age = $0?.getAge() {
                let ageString = String(describing: age)
                description = ageString
            }
            if let city = $0?.location?.city {
                description = "\(description), \(city)"
            }
            if let country = $0?.location?.country {
                description = "\(description) (\(country))"
            }
            return description
        }
    }

    func logOut() {
        LoginManager.shared.logOut()
    }

    func deleteAccount() {
        LoginManager.shared.deleteAccount()
    }

    func share(from viewController: UIViewController?) {
        ShareService.shared.share(from: viewController)
    }
}
