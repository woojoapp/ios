//
//  Decodable+Dictionary.swift
//  Woojo
//
//  Created by Edouard Goossens on 27/03/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseDatabase
import CodableFirebase

extension Decodable {
    init?(from any: Any?) throws {
        if any == nil { return nil }
        else {
            let data = try JSONSerialization.data(withJSONObject: any!, options: .prettyPrinted)
            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:sszzz"
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            self = try decoder.decode(Self.self, from: data)
        }
    }
    
    init?(from dataSnapshot: DataSnapshot?) throws {
        if dataSnapshot == nil { return nil }
        else {
            let decoder = FirebaseDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:sszzz"
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            self = try decoder.decode(Self.self, from: dataSnapshot?.value as Any)
        }
    }
}
