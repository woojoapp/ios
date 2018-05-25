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
    
    convenience init(from dataSnapshot: DataSnapshot) {
        self.init(uid: dataSnapshot.key)
        self.profile = User.Profile(dataSnapshot: dataSnapshot.childSnapshot(forPath: "profile"))
        self.profile?.photoIds = getPhotoIds(dataSnapshot: dataSnapshot)
            // TODO: Only user photos, not photoIds
        self.profile?.photos = getPhotos(dataSnapshot: dataSnapshot)
    }
    
    private func getPhotos(dataSnapshot: DataSnapshot) -> [Int: ProfilePhoto]? {
        var photos = [Int: ProfilePhoto]()
        let value =  dataSnapshot.childSnapshot(forPath: "profile/photos").value
        if let array = value as? NSArray {
            for (i, element) in array.enumerated() {
                if let photoId = element as? String {
                    photos[i] = FirebaseProfilePhoto(uid: dataSnapshot.key, id: photoId)
                }
            }
        } else if let dict = value as? [String: String] {
            for (i, element) in dict {
                if let position = Int(i) {
                    photos[position] = FirebaseProfilePhoto(uid: dataSnapshot.key, id: element)
                }
            }
        }
        return photos
    }
    
    private func getPhotoIds(dataSnapshot: DataSnapshot) -> [Int: String]? {
        var photos = [Int: String]()
        let value = dataSnapshot.childSnapshot(forPath: "profile/photos").value
        if let array = value as? NSArray {
            for (i, element) in array.enumerated() {
                if let photoId = element as? String {
                    photos[i] = photoId
                }
            }
        } else if let dict = value as? [String: String] {
            for (i, element) in dict {
                if let position = Int(i) {
                    photos[position] = element
                }
            }
        }
        return photos
    }

    class Profile: Codable {
        var firstName: String?
        var birthday: String?
        var gender: String?
        var description: String?
        var location: Location?
        var occupation: String?
        var photoIds: [Int: String]? = nil
        var photos: [Int: ProfilePhoto]? = nil

        private enum CodingKeys: String, CodingKey {
            case gender, birthday, description, location, occupation
            case firstName = "first_name"
            //case photoIds = "photos"
        }
        
        convenience init?(dataSnapshot: DataSnapshot) {
            self.init(from: dataSnapshot.value as? [String: Any])
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
    
    class Event: Hashable {
        var event: Woojo.Event
        var connection: Connection
        var active: Bool
        var hashValue: Int {
            return event.id?.hashValue ?? 0
        }
        
        init(event: Woojo.Event, connection: Connection, active: Bool = false) {
            self.event = event
            self.connection = connection
            self.active = active
        }
        
        enum Connection: String, Codable {
            case facebookGoing = "attending"
            case facebookInterested = "unsure"
            case facebookNotReplied = "not_replied"
            case eventbriteTicket
            case recommended
            case sponsored
        }
    }
}

func == (left: User.Event, right: User.Event) -> Bool {
    return left.event.id == right.event.id
}

func == (left: User, right: User) -> Bool {
    return left.uid == right.uid
}
