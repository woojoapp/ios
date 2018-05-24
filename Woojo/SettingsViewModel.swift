//
// Created by Edouard Goossens on 11/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import Branch
import FirebaseAuth
import FirebaseStorage
import RxCocoa
import RxSwift


class SettingsViewModel {
    static let shared = SettingsViewModel()
    
    private var user: Driver<User?>

    init() {
        self.user = UserRepository.shared.getUser().asDriver(onErrorJustReturn: nil)
    }

    func fullMainPicture() -> Driver<ProfilePhoto?> {
        return user.map { $0?.profile?.photos?[0] }
    }

    private(set) lazy var firstName: Driver<String?> = {
        return user.map { $0?.profile?.firstName }
    }()

    private(set) lazy var shortDescription: Driver<String> = {
        return user.map {
            var description = ""
            if let age = $0?.profile?.getAge() {
                let ageString = String(describing: age)
                description = ageString
            }
            if let city = $0?.profile?.location?.city {
                description = "\(description), \(city)"
            }
            if let country = $0?.profile?.location?.country {
                description = "\(description) (\(country))"
            }
            return description
        }
    }()

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
