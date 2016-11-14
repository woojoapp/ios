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
        placeLabel?.text = event.place?["name"] as! String?
        dateLabel?.text = Event.dateFormatter.string(from: event.start)
        if let pictureData = event.pictureData {
            thumbnailView?.image = UIImage(data: pictureData)
        }
    }

}
