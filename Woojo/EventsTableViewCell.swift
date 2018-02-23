//
//  EventsTableViewCell.swift
//  Woojo
//
//  Created by Edouard Goossens on 03/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit

class EventsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var placeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var thumbnailView: UIImageView!
    
    var event: Event? {
        didSet {
            populate(with: event)
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
    
    func populate(with event: Event?) {
        nameLabel.text = event?.name
        var placeString: String = ""
        if let place = event?.place, let placeName = place.name {
            placeString = placeName
        }
        if let location = event?.place?.location, let city = location.city {
            if placeString != "" && placeString != city {
                placeString = "\(placeString) (\(city))"
            } else {
                placeString = city
            }
        }
        if placeString == "" {
            placeString = NSLocalizedString("Unknown location", comment: "")
        }
        //cell.accessoryType
        placeLabel.text = placeString
        thumbnailView.layer.cornerRadius = 12.0
        thumbnailView.layer.masksToBounds = true
        thumbnailView.contentMode = .scaleAspectFill
        if let pictureURL = event?.pictureURL {
            thumbnailView.sd_setImage(with: pictureURL, placeholderImage: #imageLiteral(resourceName: "placeholder_100x100"))
        } else {
            thumbnailView.image = #imageLiteral(resourceName: "placeholder_100x100")
        }
        if let start = event?.start {
            dateLabel?.text = event?.timesString
        }
    }

}
