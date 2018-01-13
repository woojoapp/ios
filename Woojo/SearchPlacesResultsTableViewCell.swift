//
//  SearchPlacesResultsTableViewCell.swift
//  Woojo
//
//  Created by Edouard Goossens on 12/01/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import UIKit

class SearchPlacesResultsTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    //@IBOutlet weak var placeLabel: UILabel!
    @IBOutlet weak var thumbnailView: UIImageView!
    
    var place: Place? {
        didSet {
            populate(with: place)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func populate(with place: Place?) {
        let attributedString = NSMutableAttributedString()
        if let name = place?.name {
            attributedString.append(NSMutableAttributedString(string: name, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 17)]))
        }
        if let verificationStatus = place?.verificationStatus {
            let verifiedImage = NSTextAttachment()
            switch verificationStatus {
            case .blueVerified:
                verifiedImage.image = #imageLiteral(resourceName: "blue_verified")
            case .grayVerified:
                verifiedImage.image = #imageLiteral(resourceName: "gray_verified")
            default:
                verifiedImage.image = nil
            }
            if verifiedImage.image != nil {
                verifiedImage.bounds = CGRect(x: 0.0, y: nameLabel.font.descender / 2.0, width: verifiedImage.image!.size.width, height: verifiedImage.image!.size.height)
            }
            attributedString.append(NSAttributedString(string: " ", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 17)]))
            attributedString.append(NSAttributedString(attachment: verifiedImage))
        }
        if let location = place?.location {
            attributedString.append(NSMutableAttributedString(string: "\n\(location.addressString)", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 12)]))
        }
        nameLabel.attributedText = attributedString
        //placeLabel.text = place?.location?.addressString
        thumbnailView.layer.cornerRadius = 12.0
        thumbnailView.layer.masksToBounds = true
        if let pictureURL = place?.pictureURL {
            thumbnailView.sd_setImage(with: pictureURL, placeholderImage: #imageLiteral(resourceName: "placeholder_40x40"), options: [.cacheMemoryOnly])
        } else {
            thumbnailView.image = #imageLiteral(resourceName: "placeholder_40x40")
        }
    }
    
}
