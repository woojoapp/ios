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
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var sourceIcon: UIImageView!
    @IBOutlet weak var checkView: UIImageView!
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var activateArea: UIView!
    @IBOutlet weak var detailsView: UIView!
    
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
    
    static let humanDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.dateFormat = "dd MMM yyyy, HH:mm"
        return formatter
    }()
    
    func populate(with event: Event?) {
        populateDateOrImage(event: event)
        nameLabel.text = event?.name
        populatePlace(event: event)
        if let start = event?.start {
            dateLabel?.text = MyEventsTableViewCell.humanDateFormatter.string(from: start)
        }
        sourceLabel.text = getSourceText(event: event)
        set(active: event?.active ?? false, event: event)
    }
    
    private func populatePlace(event: Event?) {
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
        placeLabel.text = placeString
    }
    
    private func populateDateOrImage(event: Event?) {
        thumbnailView.layer.cornerRadius = 12.0
        thumbnailView.layer.masksToBounds = true
        thumbnailView.contentMode = .scaleAspectFill
        if let urlString = event?.pictureURL,
            let pictureURL = URL(string: urlString) {
            setImage(pictureURL: pictureURL, active: event?.active ?? false)
            setDateVisibility(hidden: true)
        } else {
            if let urlString = event?.coverURL,
                let pictureURL = URL(string: urlString) {
                setImage(pictureURL: pictureURL, active: event?.active ?? false)
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
    }
    
    private func getSourceIcon(source: Event.Source?) -> UIImage? {
        if let source = source {
            switch source {
            case .eventbrite: return #imageLiteral(resourceName: "Eventbrite icon")
            case .facebook: return #imageLiteral(resourceName: "Facebook icon")
            case .recommended: return #imageLiteral(resourceName: "woojo_icon")
            case .sponsored: return #imageLiteral(resourceName: "woojo_icon")
            }
        }
        return nil
    }
    
    private func getSourceText(event: Event?) -> String? {
        if let event = event {
            switch event.source {
            case .eventbrite: return NSLocalizedString("You have a ticket", comment: "")
            case .facebook:
                switch event.rsvpStatus {
                case Event.RSVP.attending.rawValue: return NSLocalizedString("You're going", comment: "")
                case Event.RSVP.unsure.rawValue: return NSLocalizedString("You're interested", comment: "")
                case Event.RSVP.notReplied.rawValue: return NSLocalizedString("You're invited", comment: "")
                default: return NSLocalizedString("You're invited", comment: "")
                }
            case .recommended: return NSLocalizedString("Recommended for you", comment: "")
            case .sponsored: return NSLocalizedString("Recommended for you", comment: "")
            }
        }
        return nil
    }
    
    private func setImage(pictureURL: URL, active: Bool) {
        thumbnailView.sd_setImage(with: pictureURL, placeholderImage: #imageLiteral(resourceName: "placeholder_40x40"), options: [], completed: { (_, _, _, _) in
            if !active {
                if let image = self.thumbnailView.image {
                    self.thumbnailView.image = image.desaturate()
                }
            }
        })
    }
    
    private func set(active: Bool, event: Event?) {
        if active {
            checkView.image = #imageLiteral(resourceName: "check")
            detailsView.alpha = 1.0
            activateArea.alpha = 1.0
            sourceIcon.image = getSourceIcon(source: event?.source)
        } else {
            checkView.image = #imageLiteral(resourceName: "plus")
            detailsView.alpha = 0.3
            activateArea.alpha = 0.3
            sourceIcon.image = getSourceIcon(source: event?.source)?.desaturate()
        }
    }
    
    func setDateVisibility(hidden: Bool) {
        monthLabel.isHidden = hidden
        dayLabel.isHidden = hidden
    }
}
