//
//  Application+UIApplicationDelegate.swift
//  Woojo
//
//  Created by Edouard Goossens on 27/05/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseDatabase
import FirebaseAuth
import FirebaseMessaging
import FirebaseRemoteConfig
import FacebookCore
import FacebookLogin
import PKHUD
import Applozic
import RxSwift
import RxCocoa
import Whisper
import UserNotifications
import Branch
import SDWebImage
import Crashlytics
import Amplitude_iOS
import AdSupport

extension Application: UIApplicationDelegate {
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = true
        AnalyticsConfiguration.shared().setAnalyticsCollectionEnabled(true)
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        setupRemoteConfig()
        Amplitude.instance().useAdvertisingIdForDeviceId()
        Amplitude.instance().initializeApiKey(Constants.Env.Analytics.amplitudeApiKey)
        
        Whisper.Config.modifyInset = false
        
        // Initialize Facebook SDK
        FacebookCore.SDKApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        if let userInfo = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? NSDictionary {
            if let notificationId = userInfo["notificationId"] as? String {
                HUD.show(.progress, onView: self.window?.rootViewController?.view)
                self.handlePushNotificationTap(notificationId: notificationId, completionHandler: nil)
            }
        }
        
        let alAppLocalNotificationHandler : ALAppLocalNotifications =  ALAppLocalNotifications.appLocalNotificationHandler();
        alAppLocalNotificationHandler.dataConnectionNotificationHandler();
        
        if (launchOptions != nil) {
            let dictionary = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? NSDictionary
            
            if (dictionary != nil) {
                let alPushNotificationService: ALPushNotificationService = ALPushNotificationService()
                let appState: NSNumber = NSNumber(integerLiteral: 0)
                let applozicProcessed = alPushNotificationService.processPushNotification(launchOptions,updateUI:appState)
                if (!applozicProcessed) {
                    
                }
            }
        }
        
        Branch.getInstance().setDebug()
        Branch.getInstance().initSession(launchOptions: launchOptions, andRegisterDeepLinkHandler: {params, error in
            if error == nil {
                // params are the deep linked params associated with the link that the user clicked -> was re-directed to this app
                // params will be empty if no data found
                // ... insert custom logic here ...
                if let params = params as? [String: AnyObject] {
                    if let action = params["action"] as? String, action == "add_event",
                        let eventId = params["event_id"] as? String {
                        EventRepository.shared.get(eventId: eventId).toPromise().then { event in
                            if let eventId = event?.id {
                                UserActiveEventRepository.shared.activateEvent(eventId: eventId).catch { _ in }
                                Application.defferedEvent = event
                            }
                        }
                    }
                }
            }
        })
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = R.storyboard.main.mainTabBarController()
        self.window?.makeKeyAndVisible()
        
        self.startListeningForNotifications()
        
        UIApplication.shared.registerForRemoteNotifications()
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("APP_ENTER_IN_BACKGROUND")
        let registerUserClientService = ALRegisterUserClientService()
        registerUserClientService.disconnect()
        
        UserRepository.shared.setLastSeen(date: Date()).catch { _ in }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "APP_ENTER_IN_BACKGROUND"), object: nil)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        let registerUserClientService = ALRegisterUserClientService()
        registerUserClientService.connect()
        ALPushNotificationService.applicationEntersForeground()
        print("APP_ENTER_IN_FOREGROUND")
        
        UserRepository.shared.setLastSeen(date: Date()).catch { _ in }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "APP_ENTER_IN_FOREGROUND"), object: nil)
        //UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        AppEventsLogger.activate(application)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        ALDBHandler.sharedInstance().saveContext()
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        // pass the url to the handle deep link call
        let branchHandled = Branch.getInstance().application(app, open: url, options: options)
        if (!branchHandled) {
            return FacebookCore.SDKApplicationDelegate.shared.application(app, open: url, options: options)
        }
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        // pass the url to the handle deep link call
        Branch.getInstance().continue(userActivity)
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("DIDREGISTERFORREMOTE")
        saveDeviceToken(deviceToken: deviceToken)
    }
    
    private func saveDeviceToken(deviceToken: Data) {
        var deviceTokenString: String = ""
        for i in 0..<deviceToken.count {
            deviceTokenString += String(format: "%02.2hhx", deviceToken[i] as CVarArg)
        }
        if (ALUserDefaultsHandler.getApnDeviceToken() != deviceTokenString) {
            let alRegisterUserClientService = ALRegisterUserClientService()
            alRegisterUserClientService.updateApnDeviceToken(withCompletion: deviceTokenString, withCompletion: { (response, error) in
                
            })
        }
        print("Saving push token", deviceTokenString, UIDevice.current.identifierForVendor?.uuidString)
        Messaging.messaging().apnsToken = deviceToken
        if let uuid = UIDevice.current.identifierForVendor?.uuidString,
            let fcm = Messaging.messaging().fcmToken {
            let device = Device(uuid: uuid, fcm: fcm, token: deviceTokenString, platform: .iOS)
            //Analytics.setUserProperties(properties: ["push_notifications_enabled": "true"])
            //Analytics.Log(event: "Preferences_push_notifications", with: ["enabled": "true"])
            print("Setting device", device.uuid)
            UserRepository.shared.setDevice(device: device).catch { _ in print("Failed to set device") }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Oh no! Failed to register for remote notifications with error \(error)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        print("Received notification :: \(userInfo)")
        let alPushNotificationService: ALPushNotificationService = ALPushNotificationService()
        
        let appState: NSNumber = NSNumber(value: 0 as Int32)                 // APP_STATE_INACTIVE
        alPushNotificationService.processPushNotification(userInfo, updateUI: appState)
        
        Branch.getInstance().handlePushNotification(userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        print("Received notification With Completion :: \(userInfo.description)")
        let alPushNotificationService: ALPushNotificationService = ALPushNotificationService()
        
        let appState: NSNumber = NSNumber(value: -1 as Int32)                // APP_STATE_BACKGROUND
        alPushNotificationService.processPushNotification(userInfo, updateUI: appState)
        completionHandler(UIBackgroundFetchResult.newData)
    }
}
