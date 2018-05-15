//
// Created by Edouard Goossens on 09/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import FacebookCore

struct UserProfilePictureGraphRequest: GraphRequestProtocol {

    struct Response: GraphResponseProtocol {

        init(rawResponse: Any?) {
            print("LOGGIN GRAPH REQUEST \(rawResponse)")
            picture = GraphAPI.ProfilePicture(from: rawResponse)
        }

        var picture: GraphAPI.ProfilePicture?
    }

    init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    private var width: Int
    private var height: Int
    var graphPath = "/me"
    var parameters: [String:Any]? {
        return ["fields": "picture.width(\(width)).height(\(height))"]
    }
    var accessToken = AccessToken.current
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion
}
