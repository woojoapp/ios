//
//  MyEventsTableViewCell.swift
//  Woojo
//
//  Created by Edouard Goossens on 21/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit

class MyEventsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var placeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var attendingLabel: UILabel!
    @IBOutlet weak var checkView: UIImageView!
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var dayLabel: UILabel!
    
    var event: Event? {
        didSet {
            populate(with: event)
        }
    }
    
    static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.dateFormat = "MMM"
        return formatter
    }()
    
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.dateFormat = "dd"
        return formatter
    }()
    
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
        var placeString = ""
        if let place = event?.place, let placeName = place.name {
            placeString = placeName
        }
        if let location = event?.place?.location, let city = location.city {
            if placeString != "" {
                placeString = "\(placeString) (\(city))"
            } else {
                placeString = city
            }
        }
        if placeString == "" {
            placeString = NSLocalizedString("Unknown location", comment: "")
        }
        thumbnailView.layer.cornerRadius = 12.0
        thumbnailView.layer.masksToBounds = true
        thumbnailView.contentMode = .scaleAspectFill
        placeLabel.text = placeString
        print(event?.pictureURL, event?.coverURL)
        if let pictureURL = event?.pictureURL {
            thumbnailView.sd_setImage(with: pictureURL, placeholderImage: #imageLiteral(resourceName: "placeholder_40x40"))
            setDateVisibility(hidden: true)
        } else {
            if let pictureURL = event?.coverURL {
                thumbnailView.sd_setImage(with: pictureURL, placeholderImage: #imageLiteral(resourceName: "placeholder_40x40"))
                setDateVisibility(hidden: true)
            } else {
                if let startDate = event?.start {
                    thumbnailView.image = nil
                    monthLabel.text = MyEventsTableViewCell.monthFormatter.string(from: startDate).uppercased()
                    dayLabel.text = MyEventsTableViewCell.dayFormatter.string(from: startDate)
                    setDateVisibility(hidden: false)
                }
            }
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
    
    func setDateVisibility(hidden: Bool) {
        monthLabel.isHidden = hidden
        dayLabel.isHidden = hidden
    }
}
