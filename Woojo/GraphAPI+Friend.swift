//
// Created by Edouard Goossens on 09/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import Foundation

extension GraphAPI {
    struct Friend {
        var id: String?
        var firstName: String?
        var picture: Picture?

        private enum CodingKeys: String, CodingKey {
            case id, picture
            case firstName = "first_name"
        }

        struct Picture:Codable {
            var data: Data?

            struct Data: Codable {
                var url: String?
            }
        }
    }
}
