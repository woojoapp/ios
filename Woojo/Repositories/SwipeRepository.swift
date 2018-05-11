//
//  SwipeRepository.swift
//  Woojo
//
//  Created by Edouard Goossens on 09/05/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth
import RxSwift
import Promises

class SwipeRepository {
    private let firebaseAuth = Auth.auth()
    private let firebaseDatabase = Database.database()
    
    static var shared = SwipeRepository()
    private init() {}
    
    private func getUid() -> String { return firebaseAuth.currentUser!.uid }

    func like(on: String, message: String? = nil) -> Promise<Void> {
        let like = Like(by: getUid(), on: on, message: message)
        return firebaseDatabase.reference()
                .child("likes")
                .child(like.by)
                .child(like.on)
                .setValuePromise(value: like.dictionary)
    }

    func pass(on: String) -> Promise<Void> {
        let pass = Pass(by: getUid(), on: on)
        return firebaseDatabase.reference()
                .child("passes")
                .child(pass.by)
                .child(pass.on)
                .setValuePromise(value: pass.dictionary)
    }
    
    func removeLike(on: String) -> Promise<Void> {
        return firebaseDatabase.reference()
                .child("likes")
                .child(getUid())
                .child(on)
                .removeValuePromise()
    }
}
