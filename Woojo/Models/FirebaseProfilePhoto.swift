//
//  FirebasePhoto.swift
//  Woojo
//
//  Created by Edouard Goossens on 24/05/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import FirebaseStorage
import Promises
import UIKit

class FirebaseProfilePhoto: ProfilePhoto {
    var uid: String
    var id: String
    var storageReference: StorageReference
    
    init(uid: String, id: String) {
        self.uid = uid
        self.id = id
        self.storageReference = Storage.storage().reference().child("users").child(uid).child("profile/photos").child(id)
    }
    
    func download() -> Promise<UIImage?> {
        return self.download(size: .full)
    }
    
    func download(size: User.Profile.Photo.Size) -> Promise<UIImage?> {
        return Promise<UIImage?> { fulfill, reject in
            UIImageView().sd_setImage(with: self.storageReference.child(size.rawValue), placeholderImage: nil) { image, error, _, _ in
                if let error = error {
                    reject(error)
                } else {
                    fulfill(image)
                }
            }
        }
    }
}
