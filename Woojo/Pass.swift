//
//  Pass.swift
//  Woojo
//
//  Created by Edouard Goossens on 04/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseDatabase

class Pass: Codable {

    var by: String
    var on: String
    var created: Date

    init(by: String, on: String) {
        self.by = by
        self.on = on
        self.created = Date()
    }
}
