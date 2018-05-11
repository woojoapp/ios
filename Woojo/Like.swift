//
//  Like.swift
//  Woojo
//
//  Created by Edouard Goossens on 04/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseDatabase

class Like: Codable {
    var by: String
    var on: String
    var created: Date
    var message: String?

    init(by: String, on: String, message: String? = nil) {
        self.by = by
        self.on = on
        self.created = Date()
        self.message = message
    }
}
