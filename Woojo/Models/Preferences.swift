//
//  Preferences.swift
//  Woojo
//
//  Created by Edouard Goossens on 06/12/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import FirebaseDatabase

struct Preferences: Codable {

    var gender: Gender
    var ageRange: AgeRange

    init() {
        self.init(gender: .all, ageRange: AgeRange())
    }

    init(gender: Gender, ageRange: AgeRange) {
        self.gender = gender
        self.ageRange = ageRange
    }

    private enum CodingKeys: String, CodingKey {
        case gender
        case ageRange = "age_range"
    }

    enum Gender: String, Codable {
        case male
        case female
        case all
    }

    struct AgeRange: Codable {
        private static let MIN = 18
        private static let MAX = 99

        init() {
            self.init(min: AgeRange.MIN, max: AgeRange.MAX)
        }

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        var min: Int
        var max: Int
    }

}