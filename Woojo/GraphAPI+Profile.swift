//
// Created by Edouard Goossens on 09/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import Foundation

extension GraphAPI {
    struct Profile: Codable {
        var id: String?
        var firstName: String?
        var birthday: String?
        var location: GraphAPI.Location?
    }
}
