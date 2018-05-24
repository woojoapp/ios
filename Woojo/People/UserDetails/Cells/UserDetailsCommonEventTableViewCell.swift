//
//  UserDetailsCommonEventTableViewCell.swift
//  Woojo
//
//  Created by Edouard Goossens on 08/04/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import UIKit

class UserDetailsCommonEventTableViewCell: UITableViewCell {

    @IBOutlet var eventTextLabel: UILabel!
    @IBOutlet var eventImageView: UIImageView!
    @IBOutlet var eventMonth: UILabel!
    @IBOutlet var eventDay: UILabel!
    
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
    
    var event: Event? {
        didSet {
            populate(with: event)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        eventImageView.contentMode = .scaleAspectFill
        eventImageView.layer.borderWidth = 1
        eventImageView.layer.borderColor = UIColor.white.cgColor
        eventImageView.layer.cornerRadius = 8.0
        eventImageView.layer.masksToBounds = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    private func setDateVisibility(hidden: Bool) {
        eventMonth.isHidden = hidden
        eventDay.isHidden = hidden
    }
    
    private func setImage(pictureURL: URL, active: Bool) {
        eventImageView.sd_setImage(with: pictureURL)
    }
    
    private func populate(with event: Event?) {
        eventTextLabel.text = event?.name
        populateDateOrImage(event: event)
    }
    
    private func populateDateOrImage(event: Event?) {
        if let urlString = event?.coverURL,
            let pictureURL = URL(string: urlString) {
            setImage(pictureURL: pictureURL, active: event?.active ?? false)
            setDateVisibility(hidden: true)
        } else {
            if let startDate = event?.start {
                eventImageView.image = nil
                eventMonth.text = UserDetailsCommonEventTableViewCell.monthFormatter.string(from: startDate).uppercased()
                eventDay.text = UserDetailsCommonEventTableViewCell.dayFormatter.string(from: startDate)
                setDateVisibility(hidden: false)
            }
        }
    }
    
}
