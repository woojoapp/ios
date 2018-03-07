//
//  Match.swift
//  Woojo
//
//  Created by Edouard Goossens on 26/10/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseDatabase

extension User {
    class Match {
        
        static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = Constants.User.Match.dateFormat
            return formatter
        }()
        
        var by: String
        var on: String
        var created: Date = Date()
        var commonEventInfos: [CommonEventInfo] = []
        var ref: DatabaseReference {
            get {
                return Database.database().reference().child(Constants.User.Match.firebaseNode).child(by).child(on)
            }
        }
        
        init(by: String, on: String) {
            self.by = by
            self.on = on
            self.created = Date()
        }
        
        init?(firebase snapshot: DataSnapshot) {
            if let value = snapshot.value as? [String:Any],
                let by = value[Constants.User.Match.properties.firebaseNodes.by] as? String,
                let on = value[Constants.User.Match.properties.firebaseNodes.on] as? String,
                let createdString = value[Constants.User.Match.properties.firebaseNodes.created] as? String,
                let created = Match.dateFormatter.date(from: createdString) {
                self.by = by
                self.on = on
                self.created = created
                for item in snapshot.childSnapshot(forPath: Constants.User.Match.properties.firebaseNodes.events).children {
                    if let commonEventInfoSnap = item as? DataSnapshot {
                        self.commonEventInfos.append(CommonEventInfo(snapshot: commonEventInfoSnap))
                    }
                }
            } else {
                print("Failed to create Match from Firebase snapshot. Nil or missing required data.", snapshot)
                return nil
            }
        }
        
        static func between(user: User, and other: User, completion: ((Match?) -> ())? = nil) {
            Database.database().reference().child(Constants.User.Match.firebaseNode).child(user.uid).child(other.uid).observeSingleEvent(of: .value) { (snapshot) in
                completion?(Match(firebase: snapshot))
            }
        }
    }
}

