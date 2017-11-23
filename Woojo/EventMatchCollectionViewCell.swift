//
//  EventMatchCollectionViewCell.swift
//  Woojo
//
//  Created by Edouard Goossens on 14/11/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import UIKit

class EventMatchCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    var user: User? {
        didSet {
            populate(with: user)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func populate(with user: User?) {
        if let user = user {
            label.text = user.profile.displayName
            imageView.layer.cornerRadius = imageView.frame.width / 2.0
            imageView.layer.masksToBounds = true
            user.profile.photos.value[0]?.download(completion: {
                self.imageView.image = user.profile.photos.value[0]?.images[.thumbnail]
                self.setNeedsLayout()
            })
        }
    }
}
