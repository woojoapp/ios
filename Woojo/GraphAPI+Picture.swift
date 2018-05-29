//
// Created by Edouard Goossens on 09/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import Foundation

extension GraphAPI {
    struct Picture: Codable {
        var id: String?
        var data: Data?

        struct Data: Codable {
            var width: Int?
            var height: Int?
            var url: String?
            var data: Foundation.Data? = nil

            private enum CodingKeys: String, CodingKey {
                case width, height, url
            }
        }
    }
}
