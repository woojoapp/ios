//
// Created by Edouard Goossens on 12/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin
import FirebaseAuth
import Promises
import Crashlytics
import Applozic

class LoginManager {
    static let shared = LoginManager()

    private init() {}

    private let facebookLoginManager = FacebookLogin.LoginManager()
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

    private func setProfilePictureFromFacebook() -> Promise<String> {
        return FacebookRepository.shared.getProfilePicture(width: 3000, height: 3000).then { picture -> Promise<String> in
            print("LOGGIN AFTER DOWNLOAD", picture)
            if let data = picture.picture?.data?.data {
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
        print("LOGGIN SET PROFILE")
        return setProfileFromFacebook().then { _ -> Promise<String> in
            print("LOGGIN SET PROFILE PICTURE")
            return self.setProfilePictureFromFacebook()
        }.then { _ -> Promise<Void> in
            print("LOGGIN SET PAGE LIKES")
            return self.setPageLikesFromFacebook()
        }.then { _ -> Promise<Void> in
            print("LOGGIN SET FRIENDS")
            return self.setFriendsFromFacebook()
        }.then { _ -> Promise<Void> in
            print("LOGGIN SET PREFERENCES")
            return self.setDefaultPreferences()
        }.then { _ -> Promise<Void> in
            print("LOGGIN SET LAST SEEN")
            return self.setLastSeen()
        }.then { _ -> Promise<Void> in
            print("LOGGIN SET SIGN UP")
            return self.setSignUp()
        }.catch { error in
            print("WOOOPS", error)
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
                        reject(LoginError.facebookPermissionsDeclined(permissions: permissions))
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
        return facebookLogin(viewController: viewController).then { facebookResult -> Promise<FirebaseAuth.User> in
            return self.firebaseLogin(credential: facebookResult.credential, permissions: facebookResult.permissions)
        }.then { firebaseUser -> Promise<FirebaseAuth.User> in
            return UserRepository.shared.isUserSignedUp().then { isUserSignedUp -> Promise<FirebaseAuth.User> in
                if isUserSignedUp {
                    print("LOGGIN HERE 1")
                    return Promise(firebaseUser)
                }
                print("LOGGIN HERE 2")
                return self.setUserFromFacebook().then {
                    return Promise(firebaseUser)
                }
            }
        }
    }

    func logOut() {
        facebookLoginManager.logOut()
        Crashlytics.sharedInstance().setUserIdentifier("")
        Analytics.Log(event: "Account_log_out")
        do {
            try Auth.auth().signOut()
            if (ALUserDefaultsHandler.isLoggedIn()) {
                let alRegisterUserClientService = ALRegisterUserClientService()
                alRegisterUserClientService.logout(completionHandler: { _, _ in
                    print("Logged out Applozic user")
                });
            }
        } catch {
            print("Failed to signOut from Firebase")
        }
    }

    func deleteAccount() {
        Analytics.Log(event: "Account_delete")
        UserRepository.shared.removeCurrentUser().then {
            self.logOut()
            Auth.auth().currentUser?.delete(completion: nil)
        }.catch { _ in }
    }

    enum LoginError: Error {
        case facebookPictureDownloadFailed
        case facebookLoginCancelled
        case facebookPermissionsDeclined(permissions: [String: String])
    }
}
