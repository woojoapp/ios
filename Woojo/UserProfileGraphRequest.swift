//
// Created by Edouard Goossens on 09/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import FacebookCore

struct UserProfileGraphRequest: GraphRequestProtocol {

    struct Response: GraphResponseProtocol {

        init(rawResponse: Any?) {
            profile = GraphAPI.Profile(from: rawResponse)
        }

        var profile: GraphAPI.Profile?
    }

    var accessToken = AccessToken.current
    var graphPath = "/me"
    var parameters: [String: Any]? = {
        let fields = ["id",
                      "first_name",
                      "birthday",
                      "gender",
                      "location{location}"]
        return ["fields": fields.joined(separator: ",")]
    }()
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion

}
