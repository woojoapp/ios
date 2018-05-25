//
//  UserDetailsViewModel.swift
//  Woojo
//
//  Created by Edouard Goossens on 22/05/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import FirebaseStorage
import RxSwift
import RxCocoa
import Promises

final class UserDetailsViewModel<T: User> {
    private var uid: String
    private var userType: T.Type
    private var user: Driver<T?>
    
    private(set) lazy var firstName: Driver<String?> = {
        [unowned self] in
        return user.map { $0?.profile?.firstName }
    }()
    
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
    
    private(set) lazy var profilePicture: Driver<UIImage?> = {
        [unowned self] in
        return UserProfileRepository.shared.getPhotoAsImage(uid: uid, position: 0, size: .full).asDriver(onErrorJustReturn: nil)
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
    
    private(set) lazy var events: Driver<[Event]> = {
        [unowned self] in
        return user.map {
            if let otherUser = $0 as? OtherUser {
                return Array(otherUser.commonInfo.events.values)
            }
            return []
        }
    }()
    
    private(set) lazy var friends: Driver<[User]> = {
        [unowned self] in
        return user.map {
            if let otherUser = $0 as? OtherUser {
                return Array(otherUser.commonInfo.friends.values)
            }
            return []
        }
    }()
    
    private(set) lazy var pageLikes: Driver<[PageLike]> = {
        [unowned self] in
        return user.map {
            if let otherUser = $0 as? OtherUser {
                return Array(otherUser.commonInfo.pageLikes.values)
            }
            return []
        }
    }()
    
    private(set) lazy var pictures: Driver<[Int: StorageReference]> = {
        [unowned self] in
        return UserProfileRepository.shared
            .getPhotos(uid: uid, size: .full)
            .flatMap({ Observable.from(optional: $0) })
            .asDriver(onErrorJustReturn: [:])
    }()
    
    private(set) lazy var loaded: Driver<Bool> = {
        [unowned self] in
        return Driver.zip(firstName, nameAge) { _, _ in return true }
    }()
    
    init(uid: String, userType: T.Type) {
        self.uid = uid
        self.userType = userType
        self.user = UserDetailsViewModel.getUser(uid: uid, userType: userType)
    }
    
    private static func getUser<T>(uid: String, userType: T.Type) -> Driver<T?> {
        switch (userType) {
        case is Match.Type:
            return UserMatchRepository.shared.getMatch(uid: uid).map { $0 as? T }.asDriver(onErrorJustReturn: nil)
        case is Candidate.Type:
            return UserCandidateRepository.shared.getCandidate(uid: uid).map { $0 as? T }.asDriver(onErrorJustReturn: nil)
        default:
            return UserRepository.shared.getUser(uid: uid).map { $0 as? T }.asDriver(onErrorJustReturn: nil)
        }
    }
    
    func unmatch() -> Promise<Void> {
        return UserSwipeRepository.shared.removeLike(on: uid)
    }
    
    func report(message: String?) -> Promise<Void> {
        return UserReportRepository.shared.setReport(onUid: uid, message: message)
    }
    
}
