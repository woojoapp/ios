//
//  CandidateCommonEventCellTableViewCell.swift
//  Woojo
//
//  Created by Edouard Goossens on 25/10/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import UIKit

class CandidateCommonEventTableViewCell: UITableViewCell {
    
    @IBOutlet var eventTextLabel: UILabel!
    @IBOutlet var eventImageView: UIImageView!
    @IBOutlet var eventMonth: UILabel!
    @IBOutlet var eventDay: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        eventImageView.contentMode = .scaleAspectFill
        eventImageView.layer.borderWidth = 1
        eventImageView.layer.borderColor = UIColor.white.cgColor
        
        eventImageView.layer.cornerRadius = 8.0
        eventImageView.layer.masksToBounds = true
        
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
    
    func setDateVisibility(hidden: Bool) {
        eventMonth.isHidden = hidden
        eventDay.isHidden = hidden
    }
    
}
