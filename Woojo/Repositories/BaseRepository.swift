//
//  Repository.swift
//  Woojo
//
//  Created by Edouard Goossens on 15/05/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import RxSwift
import Promises

class BaseRepository {
    let firebaseDatabase = Database.database()
    let firebaseStorage = Storage.storage()
    let dateFormatter: DateFormatter
    
    init() {
        self.dateFormatter = DateFormatter()
        self.dateFormatter.calendar = Calendar(identifier: .iso8601)
        self.dateFormatter.dateFormat = Constants.Event.dateFormat
    }
    
    private func getUid() -> Observable<String> {
        return AuthManager.shared.getUser().map { $0.uid }
    }
    
    private func getUserDatabaseReference(uid: String) -> DatabaseReference {
        return firebaseDatabase
            .reference()
            .child("users")
            .child(uid)
    }
    
    func getCurrentUserDatabaseReference() -> Observable<DatabaseReference> {
        return getUid().map { self.getUserDatabaseReference(uid: $0) }
    }
    
    private func getUserStorageReference(uid: String) -> StorageReference {
        return firebaseStorage
            .reference()
            .child("users")
            .child(uid)
    }
    
    func getCurrentUserStorageReference() -> Observable<StorageReference> {
        return getUid().map { self.getUserStorageReference(uid: $0) }
    }
    
    func withCurrentUser<T>(selector: @escaping (DatabaseReference) throws -> Observable<T>) -> Observable<T> {
        return getCurrentUserDatabaseReference().concatMap(selector).retry()
    }
    
    func doWithCurrentUser<T>(work: @escaping (DatabaseReference) -> Promise<T>) -> Promise<T> {
        return getCurrentUserDatabaseReference().toPromise().then { work($0) }
    }
    
    func withCurrentUserStorage<T>(selector: @escaping (StorageReference) throws -> Observable<T>) -> Observable<T> {
        return getCurrentUserStorageReference().concatMap(selector).retry()
    }
    
    func doWithCurrentUserStorage<T>(work: @escaping (StorageReference) -> Promise<T>) -> Promise<T> {
        return getCurrentUserStorageReference().toPromise().then { work($0) }
    }
}
