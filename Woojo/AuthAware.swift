//
// Created by Edouard Goossens on 12/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import FirebaseAuth
import UIKit

protocol AuthStateAware: class {
    var authStateDidChangeListenerHandle: AuthStateDidChangeListenerHandle? { get set }
}

extension AuthStateAware where Self: UIViewController {
    func startListeningForAuthStateChange() {
        authStateDidChangeListenerHandle = Auth.auth().addStateDidChangeListener { auth, user in
            if user == nil {
                self.present(LoginViewController(), animated: true)
            }
        }
    }

    func stopListeningForAuthStateChange() {
        if let handle = authStateDidChangeListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
