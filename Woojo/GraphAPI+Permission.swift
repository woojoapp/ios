                        //
//  GraphAPI+Permission.swift
//  Woojo
//
//  Created by Edouard Goossens on 25/05/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import Foundation

extension GraphAPI {
    struct Permission: Codable {
        var permission: String?
        var status: String?
    }
}
