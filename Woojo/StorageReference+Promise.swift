//
// Created by Edouard Goossens on 10/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseStorage
import Promises

extension StorageReference {
    func putDataPromise(uploadData: Data, metadata: StorageVoidMetadata? = nil) -> Promise<StorageMetadata?> {
        return Promise<StorageVoidMetadata?> { fulfill, reject in
            self.putData(uploadData: uploadData, metadata: metadata) { metadata, error in
                if error == nil { fulfill(metadata) } else { reject(error) }
            }
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
