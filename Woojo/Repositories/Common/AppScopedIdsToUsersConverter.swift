//
//  AppScopedIdsToUsersConverter.swift
//  Woojo
//
//  Created by Edouard Goossens on 23/05/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import RxSwift
import FirebaseDatabase

protocol AppScopedIdsToUsersConverter {
    
}

extension AppScopedIdsToUsersConverter {
    func transformAppScopedIdsToUsers(dataSnapshot: DataSnapshot) -> Observable<[User]> {
        let arrayOfObservables = dataSnapshot.children.reduce(into: [Observable<User?>](), { (observables, childSnapshot) in
            if let childSnapshot = childSnapshot as? DataSnapshot {
                observables.append(UserRepository.shared.getUser(appScopedId: childSnapshot.key))
            }
        })
        if dataSnapshot.childrenCount == 0 {
            return Observable.of([])
        }
        return Observable
            .combineLatest(arrayOfObservables)
            .filter({ !$0.contains(where: { $0 == nil }) })
            .map({ $0.flatMap{ $0 } as [User] })
    }
}
