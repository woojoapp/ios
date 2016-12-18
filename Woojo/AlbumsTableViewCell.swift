//
//  AlbumsTableViewCell.swift
//  Woojo
//
//  Created by Edouard Goossens on 15/12/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit

class AlbumsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var thumbnailView: UIImageView!
    
    var album: Album? {
        didSet {
            populate(with: album)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func populate(with album: Album?) {
        nameLabel.text = album?.name
        let count = album?.count ?? 0
        let s = count != 1 ? "s" : ""
        countLabel.text = "\(count) photo\(s)"
        if let pictureURL = album?.pictureURL {
            thumbnailView.sd_setImage(with: pictureURL, placeholderImage: #imageLiteral(resourceName: "placeholder_100x100"))
        } else {
            thumbnailView.image = #imageLiteral(resourceName: "placeholder_100x100")
        }
    }
    
}
