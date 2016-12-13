//
//  UserAlbumsGraphRequest.swift
//  Woojo
//
//  Created by Edouard Goossens on 13/12/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import FacebookCore

struct UserAlbumsGraphRequest: GraphRequestProtocol {
    
    struct Response: GraphResponseProtocol {
        
        init(rawResponse: Any?) {
            self.rawResponse = rawResponse
            if let dict = rawResponse as? [String:Any] {
                let albums = dict[Constants.GraphRequest.UserAlbums.keys.data] as! NSArray
                for albumData in albums {
                    if let album = Album.from(graphAPI: albumData as? [String:Any]) {
                        self.albums.append(album)
                    }
                }
            }
        }
        
        var rawResponse: Any?
        var albums: [Album] = []
        
    }
    
    var fbAccessToken: AccessToken?
    var graphPath: String {
        get {
            return Constants.GraphRequest.UserAlbums.path
        }
    }
    var parameters: [String:Any]? = [Constants.GraphRequest.fields:Constants.GraphRequest.UserAlbums.fields]
    var accessToken: AccessToken? = AccessToken.current
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion
    
}
