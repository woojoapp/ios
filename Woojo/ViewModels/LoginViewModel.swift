//
// Created by Edouard Goossens on 09/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin
import FirebaseAuth
import Promises

class LoginViewModel {
    private static let ppp = 3

    static let shared = LoginViewModel()
    private init() {}

    private let facebookLoginManager = LoginManager()
    private let firebaseAuth = Auth.auth()

    private func setProfileFromFacebook() -> Promise<Void> {
        return FacebookRepository.shared.getProfile().then { profile in
            if let woojoProfile = GraphAPIToWoojoConverter.shared.convertProfile(graphApiProfile: profile) {
                return UserProfileRepository.shared.setProfile(profile: woojoProfile)
            } else {
                return Promise(GraphAPIToWoojoConverter.ConversionError.conversionFailed)
            }
        }
    }

    private func setProfilePictureFromFacebook() -> Promise<Void> {
        return FacebookRepository.shared.getProfilePicture(width: 3000, height: 3000).then { picture -> Promise<Void> in
            if let data = picture.data?.data {
                return UserProfileRepository.shared.setPhoto(data: data, position: 0)
            }
            return Promise(LoginError.facebookPictureDownloadFailed)
        }
    }

    private func setPageLikesFromFacebook() -> Promise<Void> {
        return FacebookRepository.shared.getPageLikes().then { pageLikes in
            if let woojoPageLikes = pageLikes?.flatMap({ pageLike in GraphAPIToWoojoConverter.shared.convertPageLike(graphApiPageLike: pageLike) }) {
                return UserFacebookIntegrationRepository.shared.setPageLikes(pageLikes: woojoPageLikes)
            } else {
                return Promise(GraphAPIToWoojoConverter.ConversionError.conversionFailed)
            }
        }
    }

    private func setFriendsFromFacebook() -> Promise<Void> {
        return FacebookRepository.shared.getFriends().then { friends in
            if let woojoFriends = friends?.flatMap({ friend in GraphAPIToWoojoConverter.shared.convertFriend(graphApiFriend: friend) }) {
                return UserFacebookIntegrationRepository.shared.setFriends(friends: woojoFriends)
            } else {
                return Promise(GraphAPIToWoojoConverter.ConversionError.conversionFailed)
            }
        }
    }

    private func setDefaultPreferences() -> Promise<Void> {
        return UserRepository.shared.setPreferences(preferences: Preferences())
    }

    private func setSignUp() -> Promise<Void> {
        return UserRepository.shared.setSignUp(date: Date())
    }

    private func setLastSeen() -> Promise<Void> {
        return UserRepository.shared.setLastSeen(date: Date())
    }

    private func setUserFromFacebook() -> Promise<Void> {
        return setProfileFromFacebook().then {
            return self.setProfilePictureFromFacebook()
        }.then {
            return self.setPageLikesFromFacebook()
        }.then {
            return self.setFriendsFromFacebook()
        }.then {
            return self.setDefaultPreferences()
        }.then {
            return self.setLastSeen()
        }.then {
            return self.setSignUp()
        }
    }

    private func firebaseLogin(credential: AuthCredential, permissions: [String: String]) -> Promise<FirebaseAuth.User> {
        return Promise<FirebaseAuth.User> { fulfill, reject in
            self.firebaseAuth.signIn(with: credential) { user, error in
                if let user = user {
                    print("Firebase login success \(user.uid)")
                    Analytics.Log(event: "Account_log_in", with: permissions)
                    fulfill(user)
                }
                if let error = error {
                    print("Firebase login failure \(error.localizedDescription)")
                    reject(error)
                }
            }
        }
    }

    private func facebookLogin(viewController: UIViewController) -> Promise<(credential: AuthCredential, permissions: [String: String])> {
        return Promise<(credential: AuthCredential, permissions: [String: String])> { fulfill, reject in
            let readPermissions: [FacebookCore.ReadPermission] = [.publicProfile,
                                                                  .userFriends,
                                                                  .custom("user_events"),
                                                                  .custom("user_photos"),
                                                                  .custom("user_location"),
                                                                  .custom("user_birthday"),
                                                                  .custom("user_likes")]
            self.facebookLoginManager.logIn(readPermissions: readPermissions, viewController: viewController) { loginResult in
                switch loginResult {
                case .success(let acceptedPermissions, let declinedPermissions, let accessToken):
                    var permissions: [String: String] = [:]
                    for permission in acceptedPermissions {
                        permissions[permission.name] = "true"
                        Analytics.setUserProperties(properties: ["accepted_\(permission.name)_permission": "true"])
                    }
                    for permission in declinedPermissions {
                        permissions[permission.name] = "false"
                        Analytics.setUserProperties(properties: ["accepted_\(permission.name)_permission": "false"])
                    }
                    if declinedPermissions.count > 0 && (declinedPermissions.contains(Permission(name: "user_events")) || declinedPermissions.contains(Permission(name: "user_birthday"))) {
                        Analytics.Log(event: "Account_log_in_missing_permissions", with: permissions)
                        reject(LoginError.facebookPermissionsDeclined(permissions: declinedPermissions))
                        self.facebookLoginManager.logOut()
                    } else {
                        print("Facebook login success here", accessToken.authenticationToken)
                        let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.authenticationToken)
                        fulfill((credential: credential, permissions: permissions))
                    }
                case .failed(let error):
                    print("Facebook login error: \(error.localizedDescription)")
                    reject(error)
                case .cancelled:
                    print("Facebook login cancelled.")
                    reject(LoginError.facebookLoginCancelled)
                }
            }
        }
    }

    func loginWithFacebook(viewController: UIViewController) -> Promise<FirebaseAuth.User> {
        return facebookLogin(viewController: viewController).then { facebookResult in
            return self.firebaseLogin(credential: facebookResult.credential, permissions: facebookResult.permissions)
        }.then { firebaseUser in
            return UserRepository.shared.isUserSignedUp().then { isUserSignedUp in
                if isUserSignedUp {
                    return Promise(firebaseUser)
                }
                return self.setUserFromFacebook().then {
                    return Promise(firebaseUser)
                }
            }
        }
    }

    enum LoginError: Error {
        case facebookPictureDownloadFailed
        case facebookLoginCancelled
        case facebookPermissionsDeclined(permissions: Set<Permission>)
    }
}
