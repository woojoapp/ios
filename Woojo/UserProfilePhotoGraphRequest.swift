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
                let albums = dict[Constants.GraphRequest.UserProfilePhoto.keys.data] as! NSArray
                for album in albums {
                    if let album = album as? [String:Any] {
                        if let albumType = album[Constants.GraphRequest.UserProfilePhoto.keys.type] as? String {
                            if albumType == Constants.GraphRequest.UserProfilePhoto.keys.typeProfile {
                                if let albumCover = album[Constants.GraphRequest.UserProfilePhoto.keys.coverPhoto] as? [String:Any] {
                                    if let url = albumCover[Constants.GraphRequest.UserProfilePhoto.keys.coverPhotoSource] as? String {
                                        self.photoURL = URL(string: url)
                                    }
                                    if let id = albumCover[Constants.GraphRequest.UserProfilePhoto.keys.coverPhotoID] as? String {
                                        self.photoID = id
                                    }
                                }
                                if let picture = album[Constants.GraphRequest.UserProfilePhoto.keys.picture] as? [String:Any] {
                                    if let pictureData = picture[Constants.GraphRequest.UserProfilePhoto.keys.pictureData] as? [String:Any] {
                                        if let url = pictureData[Constants.GraphRequest.UserProfilePhoto.keys.pictureDataURL] as? String {
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

    var graphPath = Constants.GraphRequest.UserProfilePhoto.path
    var parameters: [String:Any]? = [Constants.GraphRequest.fields:Constants.GraphRequest.UserProfilePhoto.fields]
    var accessToken: AccessToken? = AccessToken.current
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion
    
}
