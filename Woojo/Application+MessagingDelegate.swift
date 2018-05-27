//
//  Application+MessagingDelegate.swift
//  Woojo
//
//  Created by Edouard Goossens on 27/05/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import FirebaseMessaging

extension Application: MessagingDelegate {
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
    }
    
    func application(received remoteMessage: MessagingRemoteMessage) {
        print("Received remote message: \(remoteMessage)")
    }
}
