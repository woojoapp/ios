//
// Created by Edouard Goossens on 09/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import FacebookCore

struct UserProfileGraphRequest: GraphRequestProtocol {

    struct Response: GraphResponseProtocol {

        init(rawResponse: Any?) {
            print("TRUCC iciii llaaa", rawResponse as? [String: Any])
            profile = GraphAPI.Profile(from: rawResponse as? [String: Any])
            profile?.firstName = (rawResponse as? [String: Any])?["first_name"] as? String
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
    var apiVersion: GraphAPIVersion = .init(stringLiteral: "2.12")

}
