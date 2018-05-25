//
// Created by Edouard Goossens on 13/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import FirebaseDatabase
import FirebaseStorage
import RxSwift
import RxCocoa
import Promises

class CandidatesViewModel {
    
    init() {}

    private(set) lazy var candidatesQuery: Observable<DatabaseQuery> = {
        return UserCandidateRepository.shared.getCandidatesQuery()
    }()

    func like(uid: String) -> Promise<Void> {
        return UserSwipeRepository.shared.like(on: uid)
    }

    func pass(uid: String) -> Promise<Void> {
        return UserSwipeRepository.shared.pass(on: uid)
    }

    func remove(uid: String) -> Promise<Void> {
        return UserCandidateRepository.shared.removeCandidate(uid: uid)
    }
    
    func share(from viewController: UIViewController?) {
        ShareService.shared.share(from: viewController)
    }
}
