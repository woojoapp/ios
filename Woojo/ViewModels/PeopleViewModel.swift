//
// Created by Edouard Goossens on 13/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import FirebaseDatabase
import RxSwift
import Promises

class PeopleViewModel {
    static let shared = PeopleViewModel()

    private init() {}

    func share(from viewController: UIViewController?) {
        ShareService.shared.share(from: viewController)
    }

    func getCandidatesQuery() -> DatabaseQuery {
        return UserCandidateRepository.shared.getCandidatesQuery()
    }

    func getOtherUser<T: OtherUser>(uid: String, otherUserType: T.Type) -> Observable<OtherUser?> {
        switch (otherUserType) {
        case is Candidate.Type:
            return UserCandidateRepository.shared.getCandidate(uid: uid)
        case is Match.Type:
            return UserMatchRepository.shared.getMatch(uid: uid)
        default:
            return Observable.of(nil)
        }
    }

    func getCandidate(uid: String) -> Observable<OtherUser?> {
        return UserCandidateRepository.shared.getCandidate(uid: uid)
    }

    func getMatch(uid: String) -> Observable<OtherUser?> {
        return UserMatchRepository.shared.getMatch(uid: uid)
    }

    func getProfile(uid: String) -> Promise<User.Profile?> {
        return UserProfileRepository.shared.getProfile(uid: uid).toPromise()
    }

    func like(uid: String) -> Promise<Void> {
        return UserSwipeRepository.shared.like(on: uid)
    }

    func pass(uid: String) -> Promise<Void> {
        return UserSwipeRepository.shared.pass(on: uid)
    }

    func remove(uid: String) -> Promise<Void> {
        return UserCandidateRepository.shared.removeCandidate(uid: uid)
    }
}
