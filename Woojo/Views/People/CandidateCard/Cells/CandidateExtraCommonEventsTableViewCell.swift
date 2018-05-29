//
//  CandidateExtraCommonEventsTableViewCell.swift
//  Woojo
//
//  Created by Edouard Goossens on 26/03/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import UIKit

class CandidateExtraCommonEventsTableViewCell: UITableViewCell {
    
    @IBOutlet var eventExtraNumberLabel: UILabel!
    @IBOutlet var eventTextLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        eventExtraNumberLabel.layer.borderWidth = 1
        eventExtraNumberLabel.layer.borderColor = UIColor.white.cgColor
        
        eventExtraNumberLabel.layer.cornerRadius = 8.0
        eventExtraNumberLabel.layer.masksToBounds = true
        
        eventTextLabel.layer.shadowColor = UIColor.black.cgColor
        eventTextLabel.layer.shadowRadius = 2.0
        eventTextLabel.layer.shadowOpacity = 1.0
        eventTextLabel.layer.shadowOffset = CGSize(width: 2, height: 2)
        eventTextLabel.layer.masksToBounds = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
