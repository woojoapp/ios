//
//  CandidateCommonEventCellTableViewCell.swift
//  Woojo
//
//  Created by Edouard Goossens on 25/10/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import UIKit

class UserCommonEventTableViewCell: UITableViewCell {
    
    @IBOutlet var eventTextLabel: UILabel!
    @IBOutlet var eventImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        eventImageView.layer.borderWidth = 1
        eventImageView.layer.borderColor = UIColor.white.cgColor
        
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
