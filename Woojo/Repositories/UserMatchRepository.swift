//
// Created by Edouard Goossens on 11/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import RxSwift
import Promises

class UserMatchRepository {
    private let firebaseAuth = Auth.auth()
    private let firebaseDatabase = Database.database()

    static var shared = UserMatchRepository()

    private init() {}

    private func getUid() -> String { return firebaseAuth.currentUser!.uid }

    func getMatch(uid: String) -> Observable<OtherUser?> {

    }
}
