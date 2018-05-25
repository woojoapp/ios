//
//  SDWebImageSource.swift
//  Woojo
//
//  Created by Edouard Goossens on 22/05/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import FirebaseStorage
import ImageSlideshow

class SDWebImageFirebaseSource : NSObject, InputSource {
    public var storageReference: StorageReference
    
    public var placeholder: UIImage?
    
    public init(storageReference: StorageReference, placeholder: UIImage? = nil) {
        self.storageReference = storageReference
        self.placeholder = placeholder
        super.init()
    }
    
    public func load(to imageView: UIImageView, with callback: @escaping (UIImage?) -> Void) {
        imageView.sd_setImage(with: storageReference, placeholderImage: placeholder) { image, _, _, _ in
            callback(image)
        }
    }
    
    public func cancelLoad(on imageView: UIImageView) {
        imageView.sd_cancelCurrentImageLoad()
    }
}
