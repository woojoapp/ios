//
//  Like.swift
//  Woojo
//
//  Created by Edouard Goossens on 04/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseDatabase

extension User {
    class Like {
        
        static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = Constants.User.Like.dateFormat
            return formatter
        }()
        
        var by: String
        var on: String
        var created: Date = Date()
        var visible: Bool?
        var message: String?
        var ref: DatabaseReference {
            get {
                return Database.database().reference().child(Constants.User.Like.firebaseNode).child(by).child(on)
            }
        }
        
        init(by: String, on: String, visible: Bool? = nil, message: String? = nil) {
            self.by = by
            self.on = on
            self.created = Date()
            self.visible = visible
            self.message = message
        }
        
        func save(completion: ((Error?) -> Void)? = nil) {
            ref.setValue(toDictionary()) { error, ref in
                completion?(error)
            }
        }
        
        func toDictionary() -> [String:Any] {
            var dict: [String:Any] = [:]
            dict[Constants.User.Like.properties.firebaseNodes.by] = by
            dict[Constants.User.Like.properties.firebaseNodes.on] = on
            dict[Constants.User.Like.properties.firebaseNodes.created] = Like.dateFormatter.string(from: created)
            if let visible = visible {
                dict[Constants.User.Like.properties.firebaseNodes.visible] = String(describing: visible)
            }
            if let message = message {
                dict[Constants.User.Like.properties.firebaseNodes.message] = message
            }
            return dict
        }
        
    }
}
