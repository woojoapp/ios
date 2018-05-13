//
// Created by Edouard Goossens on 12/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import Foundation
import Promises

class FacebookAlbumsViewModel {
    static let shared = FacebookAlbumsViewModel()

    private init() {}

    func getAlbumsFromFacebook() -> Promise<[GraphAPI.Album]?> {
        return FacebookRepository.shared.getAlbums()
    }
}
