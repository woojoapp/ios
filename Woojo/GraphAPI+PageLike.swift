//
// Created by Edouard Goossens on 09/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import Foundation

extension GraphAPI {
    struct PageLike: Codable {
        var id: String?
        var name: String?
        var picture: Picture?

        struct Picture:Codable {
            var data: Data?

            struct Data: Codable {
                var url: String?
            }
        }
    }
}
