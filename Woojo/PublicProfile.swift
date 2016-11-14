//
//  PublicProfile.swift
//  Woojo
//
//  Created by Edouard Goossens on 14/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit

protocol PublicProfile {
    
    var firstName: String { get set }
    var profilePhoto: UIImage? { get set }
    var userID: String { get set }
    
}
