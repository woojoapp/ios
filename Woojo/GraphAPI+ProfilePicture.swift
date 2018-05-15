//
//  GraphAPI+ProfilePicture.swift
//  Woojo
//
//  Created by Edouard Goossens on 15/05/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import Foundation

extension GraphAPI {
    struct ProfilePicture: Codable {
        var id: String?
        var picture: ProfilePicture.Picture?
        
        struct Picture: Codable {
            var data: ProfilePicture.Picture.Data?
            
            struct Data: Codable {
                var width: Int?
                var height: Int?
                var url: String?
                var data: Foundation.Data? = nil
                
                private enum CodingKeys: String, CodingKey {
                    case width, height, url
                }
            }
        }
    }
}
