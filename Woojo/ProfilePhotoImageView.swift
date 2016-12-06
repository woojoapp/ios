//
//  ProfilePhotoImageView.swift
//  Woojo
//
//  Created by Edouard Goossens on 02/12/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit

class ProfilePhotoImageView: UIImageView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let radius: CGFloat = self.bounds.size.width / 2.0
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }

}
