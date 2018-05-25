//
//  MyEventsTableViewCell.swift
//  Woojo
//
//  Created by Edouard Goossens on 21/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit

class EventTableViewCell: UITableViewCell {
    
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
    
    var event: User.Event? {
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
    
    func populate(with userEvent: User.Event?) {
        populateDateOrImage(userEvent: userEvent)
        nameLabel.text = userEvent?.event.name
        populatePlace(event: userEvent?.event)
        if let start = userEvent?.event.start {
            dateLabel?.text = EventTableViewCell.humanDateFormatter.string(from: start)
        }
        sourceLabel.text = getConnectionText(connection: userEvent?.connection)
        set(active: userEvent?.active ?? false, connection: userEvent?.connection)
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
    
    private func populateDateOrImage(userEvent: User.Event?) {
        let event = userEvent?.event
        thumbnailView.layer.cornerRadius = 12.0
        thumbnailView.layer.masksToBounds = true
        thumbnailView.contentMode = .scaleAspectFill
        
        if let startDate = event?.start {
            monthLabel.text = EventTableViewCell.monthFormatter.string(from: startDate).uppercased()
            dayLabel.text = EventTableViewCell.dayFormatter.string(from: startDate)
        }
        
        if let urlString = event?.coverURL,
            let pictureURL = URL(string: urlString) {
            setImage(pictureURL: pictureURL, active: userEvent?.active ?? false)
            //setDateVisibility(hidden: true)
        } else {
            thumbnailView.image = nil
            setDateVisibility(hidden: false)
        }
    }
    
    private func getConnectionIcon(connection: User.Event.Connection?) -> UIImage? {
        if let connection = connection {
            switch connection {
            case .eventbriteTicket: return #imageLiteral(resourceName: "Eventbrite icon")
            case .facebookGoing: return #imageLiteral(resourceName: "Facebook icon")
            case .facebookInterested: return #imageLiteral(resourceName: "Facebook icon")
            case .facebookNotReplied: return #imageLiteral(resourceName: "Facebook icon")
            case .recommended: return #imageLiteral(resourceName: "woojo_icon")
            case .sponsored: return #imageLiteral(resourceName: "woojo_icon")
            }
        }
        return nil
    }
    
    private func getConnectionText(connection: User.Event.Connection?) -> String? {
        if let connection = connection {
            switch connection {
            case .eventbriteTicket: return R.string.localizable.connectionEventbriteTicket()
            case .facebookGoing: return R.string.localizable.connectionFacebookGoing()
            case .facebookInterested: return R.string.localizable.connectionFacebookInterested()
            case .facebookNotReplied: return R.string.localizable.connectionFacebookNotReplied()
            case .recommended: return R.string.localizable.connectionRecommended()
            case .sponsored: return R.string.localizable.connectionRecommended()
            }
        }
        return nil
    }
    
    private func setImage(pictureURL: URL, active: Bool) {
        self.thumbnailView.sd_setImage(with: pictureURL, placeholderImage: #imageLiteral(resourceName: "placeholder_40x40"), options: [], completed: { _, error, _, _ in
            if error == nil {
                if !active {
                    if let image = self.thumbnailView.image {
                        self.thumbnailView.image = image.desaturate()
                    } /* else {
                        self.setDateVisibility(hidden: false)
                    } */
                }
            } else {
                self.setDateVisibility(hidden: false)
            }
        })
    }
    
    private func set(active: Bool, connection: User.Event.Connection?) {
        if active {
            checkView.image = #imageLiteral(resourceName: "check")
            detailsView.alpha = 1.0
            activateArea.alpha = 1.0
            sourceIcon.image = getConnectionIcon(connection: connection)
        } else {
            checkView.image = #imageLiteral(resourceName: "plus")
            detailsView.alpha = 0.5
            activateArea.alpha = 0.5
            sourceIcon.image = getConnectionIcon(connection: connection)?.desaturate()
        }
    }
    
    func setDateVisibility(hidden: Bool) {
        monthLabel.isHidden = hidden
        dayLabel.isHidden = hidden
    }
}
