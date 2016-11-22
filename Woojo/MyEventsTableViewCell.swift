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
    
    var event: Event?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func populate(with event: Event) {
        self.event = event
        nameLabel?.text = event.name
        placeLabel?.text = event.place?.name
        if let start = event.start {
            dateLabel?.text = Event.dateFormatter.string(from: start)
        }
        if let pictureURL = event.pictureURL {
            thumbnailView.sd_setImage(with: pictureURL)
        }
    }
    
}
