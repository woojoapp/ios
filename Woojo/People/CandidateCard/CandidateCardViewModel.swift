//
//  CandidateCardViewModel.swift
//  Woojo
//
//  Created by Edouard Goossens on 23/05/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import RxCocoa
import RxSwift

class CandidateCardViewModel {
    private var uid: String
    private var candidate: Driver<Candidate?>
    
    init(uid: String) {
        self.uid = uid
        self.candidate = UserCandidateRepository.shared.getCandidate(uid: uid).asDriver(onErrorJustReturn: nil)
    }
    
    private(set) lazy var firstName: Driver<String?> = {
        [unowned self] in
        return candidate.map { $0?.profile?.firstName }
    }()
    
    private(set) lazy var nameAge: Driver<String?> = {
        [unowned self] in
        return candidate.map {
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
        return candidate.map { $0?.profile?.location?.city }
    }()
    
    private(set) lazy var occupation: Driver<String?> = {
        [unowned self] in
        return candidate.map { $0?.profile?.occupation }
    }()
    
    private(set) lazy var description: Driver<String?> = {
        [unowned self] in
        return candidate.map { $0?.profile?.description }
    }()
    
    private(set) lazy var events: Driver<[Event]> = {
        [unowned self] in
        return candidate.map {
            if let candidate = $0 {
                return Array(candidate.commonInfo.events.values)
            }
            return []
        }
    }()
    
}
