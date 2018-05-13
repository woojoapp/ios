//
//  AlbumPhotosGraphRequest.swift
//  Woojo
//
//  Created by Edouard Goossens on 15/12/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import FacebookCore

struct AlbumPhotosGraphRequest: GraphRequestProtocol {
    
    struct Response: GraphResponseProtocol {
        
        init(rawResponse: Any?) {
            if let dict = rawResponse as? [String: Any] {
                photos = try [GraphAPI.Album.Photo](from: dict["data"])
            }
        }

        var photos: [GraphAPI.Album.Photo]?
        
    }
    
    var albumId: String
    var graphPath: String {
        get {
            return "\(albumId)/photos"
        }
    }
    var parameters = ["fields": "id,images"]
    var accessToken = AccessToken.current
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion
    
    init(albumId: String) {
        self.albumId = albumId
    }
    
}
