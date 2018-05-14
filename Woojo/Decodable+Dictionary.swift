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
    init?(from data: Data) {
        let decoder = JSONDecoder()
        let dateFormatter1 = DateFormatter()
        dateFormatter1.dateFormat = "yyyy-MM-dd'T'HH:mm:sszzz"
        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        decoder.dateDecodingStrategy = .custom({ decoder -> Date in
            let dateString = try decoder.singleValueContainer().decode(String.self)
            if let date = dateFormatter1.date(from: dateString) { return date }
            if let date = dateFormatter2.date(from: dateString) { return date }
            throw DecodingError.decodingDateFailed
        })
        //if let decodable = try? decoder.decode(Self.self, from: data) {
        //self = decodable
        //}
        //else { return nil }
        self = try! decoder.decode(Self.self, from: data)
    }
    
    init?(from any: Any?) {
        guard let any = any else { return nil }
        if let data = try? JSONSerialization.data(withJSONObject: any, options: .prettyPrinted) {
            self.init(from: data)
        } else { return nil }
    }
    
    init?(from dataSnapshot: DataSnapshot?) {
        guard let dataSnapshot = dataSnapshot, dataSnapshot.exists() else { return nil }
        self.init(from: dataSnapshot.value as Any)
    }
}

enum DecodingError: Error {
    case decodingDateFailed
}
