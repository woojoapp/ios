//
//  ExploreEventsTableViewCell.swift
//  Woojo
//
//  Created by Edouard Goossens on 03/11/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import UIKit

class ExploreEventsTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var placeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var attendingLabel: UILabel!
    @IBOutlet weak var checkView: UIImageView!
    
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
        var placeString = "Unknown location"
        if let place = event?.place, let placeName = place.name {
            placeString = placeName
        }
        if let location = event?.place?.location, let city = location.city {
            if placeString != "Unknown location" {
                placeString = "\(placeString) (\(city))"
            } else {
                placeString = city
            }
        }
        thumbnailView.layer.cornerRadius = 12.0
        thumbnailView.layer.masksToBounds = true
        placeLabel.text = placeString
        if let pictureURL = event?.pictureURL {
            thumbnailView.sd_setImage(with: pictureURL, placeholderImage: #imageLiteral(resourceName: "placeholder_40x40"))
        } else {
            thumbnailView.image = #imageLiteral(resourceName: "placeholder_40x40")
        }
        if let start = event?.start {
            dateLabel?.text = Event.humanDateFormatter.string(from: start)
        }
        if let attendingCount = event?.attendingCount {
            let people: String
            if attendingCount == 0 { people = "No one" }
            else if attendingCount == 1 { people = "1 person" }
            else { people = "\(attendingCount) people" }
            attendingLabel.text = "\(people) attending"
        }
    }
    
}
