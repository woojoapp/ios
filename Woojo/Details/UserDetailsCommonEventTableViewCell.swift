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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
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
    
    func setDateVisibility(hidden: Bool) {
        eventMonth.isHidden = hidden
        eventDay.isHidden = hidden
    }
    
}
