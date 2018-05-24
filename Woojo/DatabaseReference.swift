//
//  DatabaseReference+Promise.swift
//  Woojo
//
//  Created by Edouard Goossens on 09/05/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseDatabase
import Promises

extension DatabaseReference {
    func removeValue(completion: ((Error?, DatabaseReference) -> Void)? = nil) {
        if let completion = completion {
            removeValue(completionBlock: completion)
        } else {
            removeValue()
        }
    }

    func removeValuePromise() -> Promise<Void> {
        return Promise<Void> { fulfill, reject in
            self.removeValue { error, reference in
                if let error = error { reject(error) } else { fulfill(()) }
            }
        }
    }

    func setValuePromise(value: Any?) -> Promise<Void> {
        return Promise<Void> { fulfill, reject in
            self.setValue(value) { error, reference in
                if let error = error { reject(error) } else { fulfill(()) }
            }
        }
    }

    func getDataSnapshot() -> Promise<DataSnapshot> {
        return Promise<DataSnapshot> { fulfill, reject in
            self.observeSingleEvent(of: .value, with: { (dataSnapshot: DataSnapshot) -> Void in
                fulfill(dataSnapshot)
             }, withCancel: { error in
                reject(error)
            })
        }
    }
}
