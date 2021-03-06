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
    
    var album: GraphAPI.Album? {
        didSet {
            populate(with: album)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.thumbnailView.layer.cornerRadius = 12.0
        self.thumbnailView.layer.masksToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func populate(with album: GraphAPI.Album?) {
        nameLabel.text = album?.name
        let count = album?.count ?? 0
        let s = count != 1 ? "s" : ""
        countLabel.text = String(format: NSLocalizedString("%d photo%@", comment: ""), count, s)
        if let urlString = album?.picture?.data?.url {
            thumbnailView.sd_setImage(with: URL(string: urlString), placeholderImage: #imageLiteral(resourceName: "placeholder_100x100"))
        } else {
            thumbnailView.image = #imageLiteral(resourceName: "placeholder_100x100")
        }
    }
    
}
