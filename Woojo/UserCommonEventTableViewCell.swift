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
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
