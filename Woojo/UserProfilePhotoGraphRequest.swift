//
//  UserProfilePictureGraphRequest.swift
//  Woojo
//
//  Created by Edouard Goossens on 16/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import FacebookCore

struct UserProfilePhotoGraphRequest: GraphRequestProtocol {
    
    struct Response: GraphResponseProtocol {
        
        init(rawResponse: Any?) {
            self.rawResponse = rawResponse
            if let dict = rawResponse as? [String:Any] {
                let albums = dict["data"] as! NSArray
                for album in albums {
                    if let album = album as? [String:Any] {
                        if let albumType = album["type"] as? String {
                            if albumType == "profile" {
                                if let albumCover = album["cover_photo"] as? [String:Any] {
                                    if let url = albumCover["source"] as? String {
                                        self.photoURL = URL(string: url)
                                    }
                                    if let id = albumCover["id"] as? String {
                                        self.photoID = id
                                    }
                                }
                                if let picture = album["picture"] as? [String:Any] {
                                    if let pictureData = picture["data"] as? [String:Any] {
                                        if let url = pictureData["url"] as? String {
                                            self.thumbnailURL = URL(string: url)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    
        var rawResponse: Any?
        var photoURL: URL?
        var photoID: String?
        var thumbnailURL: URL?
    
    }

    var graphPath = "/me/albums"
    var parameters: [String:Any]? = ["fields": "type, picture.type(small), cover_photo{source}"]
    var accessToken: AccessToken? = AccessToken.current
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion
    
}
