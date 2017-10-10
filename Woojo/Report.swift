//
//  Report.swift
//  Woojo
//
//  Created by Edouard Goossens on 07/10/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//
import Foundation
import FirebaseDatabase

extension User {
    class Report {
        
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
        var message: String?
        var ref: FIRDatabaseReference {
            get {
                return FIRDatabase.database().reference().child(Constants.User.Report.firebaseNode).child(by).child(on)
            }
        }
        
        init(by: String, on: String, message: String? = nil) {
            self.by = by
            self.on = on
            self.created = Date()
            self.message = message
        }
        
        func save(completion: ((Error?) -> Void)? = nil) {
            ref.setValue(toDictionary()) { error, ref in
                completion?(error)
            }
        }
        
        func toDictionary() -> [String:Any] {
            var dict: [String:Any] = [:]
            dict[Constants.User.Report.properties.firebaseNodes.by] = by
            dict[Constants.User.Report.properties.firebaseNodes.on] = on
            dict[Constants.User.Report.properties.firebaseNodes.created] = Like.dateFormatter.string(from: created)
            if let message = message {
                dict[Constants.User.Report.properties.firebaseNodes.message] = message
            }
            return dict
        }
        
    }
}
