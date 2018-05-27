//
//  Application+UNUserNotificationCenterDelegate.swift
//  Woojo
//
//  Created by Edouard Goossens on 27/05/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import UserNotifications

extension Application: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let notificationId = response.notification.request.content.userInfo["notificationId"] as? String {
            handlePushNotificationTap(notificationId: notificationId, completionHandler: completionHandler)
        }
    }
}

