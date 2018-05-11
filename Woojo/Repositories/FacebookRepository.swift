//
// Created by Edouard Goossens on 09/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import FacebookCore
import Promises

class FacebookRepository {
    static var shared = FacebookRepository()
    private init() {}

    func downloadPicture(url: URL) -> Promise<Data> {
        return Promise<Data> { fulfill, reject in
            do {
                fulfill(try Data(contentsOf: url))
            } catch(let downloadError) {
                reject(downloadError)
            }
        }
    }

    func getProfile() -> Promise<GraphAPI.Profile?> {
        return Promise<GraphAPI.Profile?> { fulfill, reject in
            UserProfileGraphRequest().start { response, result in
                switch result {
                case .success(let response): fulfill(response.profile)
                        // Update Firebase with the data loaded from Facebook
                        /* self.firstName = response.profile?.firstName
                if let responseAsDictionary = response.profile.dictionary {
                    print(responseAsDictionary)
                    self.ref?.updateChildValues(responseAsDictionary) { error, _ in
                        if let error = error {
                            print("Failed to update user profile in database: \(error)")
                        }
                        if let firstName = response.profile?.displayName {
                            Analytics.setUserProperties(properties: ["first_name": firstName])
                        }
                        if let gender = response.profile?.gender {
                            Analytics.setUserProperties(properties: ["gender": gender.rawValue])
                        }
                        if let birthDate = response.profile?.birthday {
                            let birthDateString = self.birthdayFirebaseFormatter.string(from: birthDate)
                            Analytics.setUserProperties(properties: ["birth_date": birthDateString])
                        }
                        completion(error)
                    }
                    self.ref?.child(Constants.User.Properties.fbAppScopedID).setValue(response.fbAppScopedID)
                    if let fbAppScopedId = response.fbAppScopedID {
                        Analytics.setUserProperties(properties: ["facebook_app_scoped_id": fbAppScopedId])
                    }
                } */
                case .failed(let error): reject(error)
                }
            }
        }
    }

    func getProfilePicture(width: Int, height: Int) -> Promise<GraphAPI.Picture> {
        return Promise<GraphAPI.Picture> { fulfill, reject in
            UserProfilePictureGraphRequest(width: width, height: height).start { response, result in
                switch result {
                case .success(let response):
                    if var picture: GraphAPI.Picture = response.picture,
                       let urlString = picture.data?.url,
                       let url = URL(string: urlString) {
                        self.downloadPicture(url: url).then { data in
                            picture.data?.data = data
                            fulfill(picture)
                        }
                    } else { reject(DownloadError.pictureUrlMissing) }
                case .failed(let error): reject(error)
                }
            }
        }
    }

    func getPageLikes() -> Promise<[GraphAPI.PageLike]?> {
        return Promise<[GraphAPI.PageLike]?> { fulfill, reject in
            UserPageLikesGraphRequest().start { response, result in
                switch result {
                case .success(let response): fulfill(response.pageLikes)
                case .failed(let error): reject(error)
                }
            }
        }
    }

    func getFriends() -> Promise<[GraphAPI.Friend]?> {
        return Promise<[GraphAPI.Friend]?> { fulfill, reject in
            UserFriendsGraphRequest().start { response, result in
                switch result {
                case .success(let response): fulfill(response.friends)
                case .failed(let error): reject(error)
                }
            }
        }
    }

    func getAlbums() -> Promise<[GraphAPI.Friend]?> {
        return Promise<[GraphAPI.Friend]?> { fulfill, reject in
            UserFriendsGraphRequest().start { response, result in
                switch result {
                case .success(let response): fulfill(response.friends)
                case .failed(let error): reject(error)
                }
            }
        }
    }

    enum DownloadError: Error {
        case pictureUrlMissing
    }
}
