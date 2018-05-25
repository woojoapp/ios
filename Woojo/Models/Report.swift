//
//  Report.swift
//  Woojo
//
//  Created by Edouard Goossens on 07/10/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//
import Foundation
import FirebaseDatabase

class Report: Codable {
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