//
//  Candidate.swift
//  Woojo
//
//  Created by Edouard Goossens on 04/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage


// TODO: Candidate should implement the PublicProfile protocol 

struct Candidate {
    
    let uid: String
    let n: Int
    let created: Date
    var profilePhoto: UIImage?
    
}

extension Candidate {
    
    static let dateFormatter: DateFormatter = {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
        return formatter
    }()
    
    static func from(snapshot: FIRDataSnapshot) -> Candidate? {
        let value = snapshot.value as! [String:Any]
        if let uid = value["uid"] as? String,
            let n = value["n"] as? Int,
            let created = value["created"] as? Double {
            return Candidate(uid: uid, n: n, created: Date(timeIntervalSince1970: created as Double), profilePhoto: nil)
        }
        return nil
    }
    
    func toAny() -> Any {
        return [
            "uid": self.uid,
            "n": self.n,
            "created": self.created.timeIntervalSince1970
        ]
    }
    
    func getPicture(handler: @escaping (_ image:UIImage?) -> Void) {
        let storageRef = FIRStorage.storage().reference(forURL: "gs://resplendent-fire-3481.appspot.com")
        let pictureRef = storageRef.child("images").child("prospects").child(self.uid)
        pictureRef.data(withMaxSize: 1 * 1024 * 1024) { (data, error) in
            if error != nil {
                print("Error getting picture for \(self.uid)")
            } else {
                handler(UIImage(data: data!))
            }
        }
    }
}
