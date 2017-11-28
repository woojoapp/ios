//
//  FacebookAlbum.swift
//  Woojo
//
//  Created by Edouard Goossens on 13/12/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import FacebookCore
import FirebaseAuth

class Album {
    
    var id: String
    var name: String?
    var count: Int?
    var pictureURL: URL?
    
    static func from(graphAPI dict: [String:Any]?) -> Album? {
        
        if let dict = dict,
            let id = dict[Constants.Album.properties.graphAPIKeys.id] as? String,
            let name = dict[Constants.Album.properties.graphAPIKeys.name] as? String {
            let album = Album(id: id)
            if let picture = dict[Constants.Album.properties.graphAPIKeys.picture] as? [String:Any] {
                if let pictureData = picture[Constants.Album.properties.graphAPIKeys.pictureData] as? [String:Any] {
                    if let url = pictureData[Constants.Album.properties.graphAPIKeys.pictureDataURL] as? String {
                        album.pictureURL = URL(string: url)
                    }
                }
            }
            album.name = name
            album.count = dict[Constants.Album.properties.graphAPIKeys.count] as? Int
            return album
        } else {
            print("Failed to create Album from Graph API dictionary. Nil or missing required data.", dict as Any)
            return nil
        }
        
    }
    
    init(id: String) {
        self.id = id
    }
    
    func getPhotos(completion: @escaping ([Photo]) -> Void) {
        if AccessToken.current != nil {
            if Auth.auth().currentUser != nil {
                let albumPhotosGraphRequest = AlbumPhotosGraphRequest(album: self)
                albumPhotosGraphRequest.start { response, result in
                    switch result {
                    case .success(let response):
                        completion(response.photos)
                    case .failed(let error):
                        print("AlbumPhotosGraphRequest failed: \(error.localizedDescription)")
                    }
                }
            } else {
                print("Failed to load user albums data from Facebook: No authenticated Firebase user.")
            }
        } else {
            print("Failed to load user albums from Facebook: No Facebook access token.")
        }
    }
    
    class Photo {
        
        class Image {
            
            var width: Int = 0
            var height: Int = 0
            var url: URL?
            
            static func from(graphAPI dict: [String:Any]?) -> Image? {
                
                if let dict = dict,
                    let width = dict[Constants.GraphRequest.AlbumPhotos.keys.imageWidth] as? Int,
                    let height = dict[Constants.GraphRequest.AlbumPhotos.keys.imageHeight] as? Int,
                    let urlString = dict[Constants.GraphRequest.AlbumPhotos.keys.imageURL] as? String,
                    let url = URL(string: urlString) {
                    let image = Image()
                    image.width = width
                    image.height = height
                    image.url = url
                    return image
                } else {
                    print("Failed to create Album.Photo.Image from Graph API dictionary. Nil or missing required data.", dict as Any)
                    return nil
                }
                
            }
            
        }
        
        var id: String?
        var images: [Image] = []
        
        static func from(graphAPI dict: [String:Any]?) -> Photo? {
            
            if let dict = dict,
                let id = dict[Constants.GraphRequest.AlbumPhotos.keys.id] as? String {
                let photo = Photo()
                photo.id = id
                if let images = dict[Constants.GraphRequest.AlbumPhotos.keys.images] as? NSArray {
                    for imageData in images {
                        if let image = Image.from(graphAPI: imageData as? [String:Any]) {
                            photo.images.append(image)
                        }
                    }
                }
                return photo
            } else {
                print("Failed to create Album.Photo from Graph API dictionary. Nil or missing required data.", dict as Any)
                return nil
            }
            
        }
        
        func isBigEnough(size: User.Profile.Photo.Size) -> Bool {
            let biggerImages = images.filter{ $0.width > size.rawValue && $0.height > size.rawValue }
            return biggerImages.count > 0
        }
        
        func getSmallestBigEnoughImage(size: User.Profile.Photo.Size) -> Image? {
            let biggerImages = images.filter{ $0.width > size.rawValue && $0.height > size.rawValue }
            if biggerImages.count == 0 {
                print("Couldn't find an image big enough to fit format")
                return nil
            }
            let best = biggerImages.min { $0.width * $0.height < $1.width * $1.height }
            return best
        }
        
        func getBiggestImage() -> Image? {
            let biggestImage = images.max { $0.width * $0.height < $1.width * $1.height }
            return biggestImage
        }
        
    }
    
}
