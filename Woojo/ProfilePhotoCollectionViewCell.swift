//
//  ProfilePhotoCollectionViewCell.swift
//  Woojo
//
//  Created by Edouard Goossens on 12/12/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit

class ProfilePhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var addButton: UIButton!
    
    var photo: User.Profile.Photo?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
