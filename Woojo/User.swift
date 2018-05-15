//
//  UserProtocol.swift
//  Woojo
//
//  Created by Edouard Goossens on 22/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage
import FacebookCore
import RxSwift

class User: Equatable, Codable {
    var uid: String
    var profile: Profile?

    init(uid: String) {
        self.uid = uid
    }

    class Profile: Codable {
        var uid: String?
        var firstName: String?
        var birthday: String?
        var gender: String?
        var description: String?
        var location: Location?
        var occupation: String?
        var photoIds: [Int: String]? = nil

        private enum CodingKeys: String, CodingKey {
            case uid, gender, birthday, description, location, occupation
            case firstName = "first_name"
            //case photoIds = "photos"
        }
        
        convenience init?(dataSnapshot: DataSnapshot) {
            self.init(from: dataSnapshot.value as? [String: Any])
            if let array = dataSnapshot.childSnapshot(forPath: "photos").value as? NSArray {
                var photos = [Int: String]()
                for (i, element) in array.enumerated() {
                    if let photoId = element as? String {
                        photos[i] = photoId
                    }
                }
                self.photoIds = photos
            }
        }

        func getBirthDate() -> Date? {
            guard let birthday = birthday else { return nil }
            let shortFormat = DateFormatter()
            shortFormat.dateFormat = "MM/dd/yyyy"
            let longFormat = DateFormatter()
            longFormat.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZ"
            for format in [shortFormat, longFormat] {
                if let birthDate = format.date(from: birthday) {
                    return birthDate
                }
            }
            return nil
        }

        func getAge() -> Int? {
            guard let birthDate = getBirthDate() else { return nil }
            return Calendar.current.dateComponents([Calendar.Component.year], from: birthDate, to: Date()).year
        }

        class Photo {
            enum Size: String {
                case thumbnail
                case full
            }

            static let sizes = [Size.thumbnail: 200, Size.full: 414]
            static let aspectRatio = Float(1.6)
            static let ppp = 3
        }

    }
}

func == (left: User, right: User) -> Bool {
    return left.uid == right.uid
}
