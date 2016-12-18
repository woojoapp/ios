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
            self.rawResponse = rawResponse
            if let dict = rawResponse as? [String:Any] {
                let photos = dict[Constants.GraphRequest.AlbumPhotos.keys.data] as! NSArray
                for photoData in photos {
                    if let photo = Album.Photo.from(graphAPI: photoData as? [String:Any]) {
                        self.photos.append(photo)
                    }
                }
            }
        }
        
        var rawResponse: Any?
        var photos: [Album.Photo] = []
        
    }
    
    var album: Album
    var graphPath: String {
        get {
            return self.album.id + Constants.GraphRequest.AlbumPhotos.path
        }
    }
    var parameters: [String:Any]? = [Constants.GraphRequest.fields:Constants.GraphRequest.AlbumPhotos.fields]
    var accessToken: AccessToken? = AccessToken.current
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion
    
    init(album: Album) {
        self.album = album
    }
    
}
