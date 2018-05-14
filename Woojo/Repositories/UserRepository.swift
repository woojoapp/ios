//
//  UserStore.swift
//  Woojo
//
//  Created by Edouard Goossens on 28/04/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import CodableFirebase
import RxSwift
import Promises

class UserRepository {
    private let firebaseAuth = Auth.auth()
    private let firebaseDatabase = Database.database()
    private let firebaseStorage = Storage.storage()
    private let dateFormatter: DateFormatter
    
    static let shared = UserRepository()
    private init() {
        self.dateFormatter = DateFormatter()
        self.dateFormatter.calendar = Calendar(identifier: .iso8601)
        self.dateFormatter.dateFormat = Constants.Event.dateFormat
    }

    private func getUid() -> String { return firebaseAuth.currentUser!.uid }

    private func getUserDatabaseReference(uid: String) -> DatabaseReference {
        return firebaseDatabase
                .reference()
                .child("users")
                .child(uid)
    }

    private func getCurrentUserDatabaseReference() -> DatabaseReference {
        return getUserDatabaseReference(uid: getUid())
    }
    
    func getPreferences() -> Observable<Preferences?> {
        return getCurrentUserDatabaseReference().child("preferences")
            .rx_observeEvent(event: .value).map { Preferences(from: $0) }
    }
    
    func setPreferences(preferences: Preferences) -> Promise<Void> {
        return getCurrentUserDatabaseReference().child("preferences").setValuePromise(value: preferences.dictionary)
    }

    func setSignUp(date: Date) -> Promise<Void> {
        return getCurrentUserDatabaseReference().child("activity/sign_up").setValuePromise(value: dateFormatter.string(from: date))
    }

    func setLastSeen(date: Date) -> Promise<Void> {
        return getCurrentUserDatabaseReference().child("activity/last_seen").setValuePromise(value: dateFormatter.string(from: date))
    }

    func isUserSignedUp() -> Promise<Bool> {
        return getCurrentUserDatabaseReference().child("activity/sign_up").getDataSnapshot().then { dataSnapshot in
            return dataSnapshot.value as? Bool ?? false
        }
    }

    func addDevice(device: Device) -> Promise<Void> {
        if device.token.isNullOrEmpty()  { return Promise(UserRepositoryError.deviceTokenNullOrEmpty) }
        return getCurrentUserDatabaseReference().child("devices").child(device.token!).setValuePromise(value: device.dictionary)
    }

    func getBotUid() -> Promise<String?> {
        return getCurrentUserDatabaseReference().child("bot/uid").getDataSnapshot().then { dataSnapshot in return Promise(dataSnapshot.value as? String) }
    }

    func removeCurrentUser() -> Promise<Void> {
        return getCurrentUserDatabaseReference().removeValuePromise()
    }

    enum UserRepositoryError: Error {
        case deviceTokenNullOrEmpty
    }
    
}
