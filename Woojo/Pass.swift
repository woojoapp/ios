//
//  Pass.swift
//  Woojo
//
//  Created by Edouard Goossens on 04/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseDatabase

extension User {
    class Pass {
        
        static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = Constants.User.Pass.dateFormat
            return formatter
        }()
        
        var by: String
        var on: String
        var created: Date = Date()
        var ref: DatabaseReference {
            get {
                return Database.database().reference().child(Constants.User.Pass.firebaseNode).child(by).child(on)
            }
        }
        
        init(by: String, on: String) {
            self.by = by
            self.on = on
            self.created = Date()
        }
        
        func save(completion: ((Error?) -> Void)? = nil) {
            ref.setValue(toDictionary()) { error, ref in
                completion?(error)
            }
        }
        
        func toDictionary() -> [String:Any] {
            var dict: [String:Any] = [:]
            dict[Constants.User.Like.properties.firebaseNodes.created] = Pass.dateFormatter.string(from: created)
            return dict
        }
        
    }
}
