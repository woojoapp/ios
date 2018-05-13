//
// Created by Edouard Goossens on 11/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import Foundation

extension GraphAPI {
    struct Album: Codable {
        var id: String?
        var name: String?
        var count: Int?
        var picture: GraphAPI.Picture?

        struct Photo: Codable {
            var id: String?
            var images: [Image]

            struct Image: Codable {
                var width: Int?
                var height: Int?
                var source: String?
            }
        }
    }
}
