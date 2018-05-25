//
//  UserCommonItemCollectionViewCell.swift
//  Woojo
//
//  Created by Edouard Goossens on 07/11/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import UIKit

class UserCommonItemCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    var item: CommonItem? {
        didSet {
            populate(with: item)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func populate(with item: CommonItem?) {
        if let item = item {
            label.text = item.name
            imageView.layer.cornerRadius = imageView.frame.width / 2.0
            imageView.layer.masksToBounds = true
            imageView.sd_setImage(with: item.pictureURL, placeholderImage: #imageLiteral(resourceName: "placeholder_100x100"))
        }
        setNeedsLayout()
    }

}
