//
// Created by Edouard Goossens on 11/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth
import RxSwift
import Promises

class UserReportRepository {
    private let firebaseAuth = Auth.auth()
    private let firebaseDatabase = Database.database()

    static var shared = UserReportRepository()

    private init() {}

    private func getUid() -> String { return firebaseAuth.currentUser!.uid }

    func setReport(onUid: String, message: String?) -> Promise<Void> {
        let report = Report(by: getUid(), on: onUid, message: message)
        return firebaseDatabase
                .reference()
                .child("reports")
                .child(report.by)
                .child(report.on)
                .setValuePromise(value: report.dictionary)
    }

}
