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

    func loginWithFacebook(viewController: UIViewController) -> Promise<FirebaseAuth.User> {
        return LoginManager.shared.loginWithFacebook(viewController: viewController)
    }

    func logout() {
        LoginManager.shared.logOut()
    }
}
