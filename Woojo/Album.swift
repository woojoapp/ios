//
//  FacebookAlbum.swift
//  Woojo
//
//  Created by Edouard Goossens on 13/12/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation

class Album {
    
    var id: String?
    var name: String?
    var count: Int?
    var pictureURL: URL?
    
    static func from(graphAPI dict: [String:Any]?) -> Album? {
        
        if let dict = dict,
            let id = dict[Constants.Album.properties.graphAPIKeys.id] as? String,
            let name = dict[Constants.Album.properties.graphAPIKeys.name] as? String {
            let album = Album()
            if let picture = dict[Constants.Album.properties.graphAPIKeys.picture] as? [String:Any] {
                if let pictureData = picture[Constants.Album.properties.graphAPIKeys.pictureData] as? [String:Any] {
                    if let url = pictureData[Constants.Album.properties.graphAPIKeys.pictureDataURL] as? String {
                        album.pictureURL = URL(string: url)
                    }
                }
            }
            album.id = id
            album.name = name
            album.count = dict[Constants.Album.properties.graphAPIKeys.count] as? Int
            return album
        } else {
            print("Failed to create Event from Graph API dictionary. Nil or missing required data.", dict as Any)
            return nil
        }
        
    }
    
}
