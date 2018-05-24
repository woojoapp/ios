//
//  UserCommonFriendCollectionViewCell.swift
//  Woojo
//
//  Created by Edouard Goossens on 23/05/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import UIKit

class UserCommonFriendCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    var user: User? {
        didSet {
            populate(with: user)
        }
    }
    
    func populate(with user: User?) {
        label.text = user?.profile?.firstName
        imageView.layer.cornerRadius = imageView.frame.width / 2.0
        imageView.layer.masksToBounds = true
        if let uid = user?.uid,
            let pictureId = user?.profile?.photoIds?[0] {
            let storageReference = UserProfileRepository.shared.getPhotoStorageReferenceSnapshot(uid: uid, pictureId: pictureId, size: .thumbnail)
            imageView.sd_setImage(with: storageReference)
        }
        setNeedsLayout()
    }

}
