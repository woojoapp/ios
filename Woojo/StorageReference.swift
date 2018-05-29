//
// Created by Edouard Goossens on 10/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseStorage
import Promises

extension StorageReference {
    func putDataPromise(uploadData: Data) -> Promise<Void> {
        return Promise<Void> { fulfill, reject in
            self.putData(uploadData, metadata: nil, completion: { _, error in
                if let error = error { reject(error) } else { fulfill(()) }
            })
        }
    }

    func deletePromise() -> Promise<Void> {
        return Promise<Void> { fulfill, reject in
            self.delete { error in
                if let error = error { reject(error) } else { fulfill(()) }
            }
        }
    }
}
