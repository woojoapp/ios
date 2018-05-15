//
//  AuthManager.swift
//  Woojo
//
//  Created by Edouard Goossens on 15/05/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import FirebaseAuth
import RxSwift

class AuthManager {
    static let shared = AuthManager()
    
    private init() {}
    
    func getUser() -> Observable<FirebaseAuth.User> {
        return Observable.create { observer in
            let handle = Auth.auth().addStateDidChangeListener { auth, user in
                observer.on(.next(user))
            }
            return Disposables.create {
                Auth.auth().removeStateDidChangeListener(handle)
            }
        }.flatMap { Observable.from(optional: $0) }
    }
}
