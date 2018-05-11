//
// Created by Edouard Goossens on 09/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import Foundation

extension GraphAPI {
    struct Location: Codable {
        var id: String?
        var name: String?
        var city: String?
        var country: String?
        var zip: String?
        var street: String?
        var latitude: Float?
        var longitude: Float?
    }
}
