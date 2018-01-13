//
//  Place.swift
//  Woojo
//
//  Created by Edouard Goossens on 18/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseDatabase
import RxSwift

struct Place {
    
    var id: String?
    var name: String?
    var location: Location?
    var pictureURL: URL?
    var coverURL: URL?
    var verificationStatus: VerificationStatus?
    var displayString: String {
        get {
            var placeString = Constants.Place.defaultDisplayString
            if let placeName = name {
                placeString = placeName
            }
            if let location = location, let city = location.city {
                if placeString != Constants.Place.defaultDisplayString && placeString != city {
                    placeString = "\(placeString) (\(city))"
                } else {
                    placeString = city
                }
            }
            return placeString
        }
    }
    
    enum VerificationStatus: String {
        case notVerified = "not_verified"
        case grayVerified = "gray_verified"
        case blueVerified = "blue_verified"
    }
    
}

extension Place {
    static func from(firebase snapshot: DataSnapshot) -> Place? {
        if let value = snapshot.value as? [String:Any] {
            var place = Place()
            place.id = value[Constants.Place.properties.firebaseNodes.id] as? String
            place.name = value[Constants.Place.properties.firebaseNodes.name] as? String
            if let verificationStatus = value[Constants.Place.properties.firebaseNodes.verificationStatus] as? String {
                place.verificationStatus = VerificationStatus(rawValue: verificationStatus)
            }
            place.location = Location.from(firebase: snapshot.childSnapshot(forPath: Constants.Place.properties.firebaseNodes.location))
            if let pictureURLString = value[Constants.Place.properties.firebaseNodes.pictureURL] as? String {
                place.pictureURL = URL(string: pictureURLString)
            }
            if let coverURLString = value[Constants.Place.properties.firebaseNodes.coverURL] as? String {
                place.coverURL = URL(string: coverURLString)
            }
            return place
        } else {
            return nil
        }
    }
    
    static func from(graphAPI dict: [String:Any]?) -> Place? {
        if let dict = dict {
            var place = Place()
            place.id = dict[Constants.Place.properties.graphAPIKeys.id] as? String
            place.name = dict[Constants.Place.properties.graphAPIKeys.name] as? String
            place.location = Location.from(graphAPI: dict[Constants.Place.properties.graphAPIKeys.location] as? [String:Any])
            if let verificationStatus = dict[Constants.Place.properties.graphAPIKeys.verificationStatus] as? String {
                place.verificationStatus = VerificationStatus(rawValue: verificationStatus)
            }
            if let picture = dict[Constants.Place.properties.graphAPIKeys.picture] as? [String:Any] {
                if let pictureData = picture[Constants.Place.properties.graphAPIKeys.pictureData] as? [String:Any] {
                    if let url = pictureData[Constants.Place.properties.graphAPIKeys.pictureDataURL] as? String {
                        place.pictureURL = URL(string: url)
                    }
                }
            }
            if let cover = dict[Constants.Place.properties.graphAPIKeys.cover] as? [String:Any] {
                if let coverSource = cover[Constants.Place.properties.graphAPIKeys.coverSource] as? String {
                    place.coverURL = URL(string: coverSource)
                }
            }
            return place
        } else {
            return nil
        }
    }
    
    func toDictionary() -> [String:Any] {
        var dict: [String:Any] = [:]
        dict[Constants.Place.properties.firebaseNodes.id] = self.id
        dict[Constants.Place.properties.firebaseNodes.name] = self.name
        dict[Constants.Place.properties.firebaseNodes.location] = self.location?.toDictionary()
        dict[Constants.Place.properties.firebaseNodes.pictureURL] = self.pictureURL?.absoluteString
        dict[Constants.Place.properties.firebaseNodes.coverURL] = self.coverURL?.absoluteString
        dict[Constants.Place.properties.firebaseNodes.verificationStatus] = self.verificationStatus?.rawValue
        return dict
    }
    
    static func search(query:String) -> Observable<[Place]> {
        return Observable.create { observer in
            SearchPlacesGraphRequest(query: query).start { response, result in
                switch result {
                case .success(let response):
                    observer.onNext(response.places)
                    observer.onCompleted()
                case .failed(let error):
                    print("SearchPlacesGraphRequest failed: \(error.localizedDescription)")
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
}
