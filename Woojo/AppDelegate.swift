//
//  AppDelegate.swift
//  Woojo
//
//  Created by Edouard Goossens on 03/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import Firebase
import FacebookCore
import FacebookLogin
//import LayerKit
import Applozic
import RxSwift
import RxCocoa

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let loginViewController = LoginViewController(nibName: "LoginViewController", bundle: nil)
    //var chatManager: ALChatManager
    
    override init() {
        FIRApp.configure()
        FIRDatabase.database().persistenceEnabled = true
        loginViewController.modalTransitionStyle = .flipHorizontal
        //self.chatManager = ALChatManager(applicationKey: "woojoa4cb24509376f2a59dd5e56caf935bf7")
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize Facebook SDK
        FacebookCore.SDKApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        if AccessToken.current == nil {
            self.window?.makeKeyAndVisible()
            self.window?.rootViewController?.present(loginViewController, animated: true, completion: nil)
        }
        
        FIRAuth.auth()?.addStateDidChangeListener { auth, user in
            if Woojo.User.current.value == nil || (Woojo.User.current.value != nil && !Woojo.User.current.value!.isLoading.value && Woojo.User.current.value!.uid != user?.uid) {
                if let currentUser = CurrentUser() {
                    currentUser.load {
                        self.loginViewController.dismiss(animated: true, completion: nil)
                    }
                } else {
                    print("No user signed in")
                    let registerUserClientService: ALRegisterUserClientService = ALRegisterUserClientService()
                    registerUserClientService.logout {
                        
                    }
                    // Show the login controller
                    if self.window?.rootViewController?.presentedViewController != self.loginViewController {
                        self.window?.makeKeyAndVisible()
                        self.window?.rootViewController?.present(self.loginViewController, animated: true, completion: nil)
                    }
                }
            }
        }
        
        let alAppLocalNotificationHandler : ALAppLocalNotifications =  ALAppLocalNotifications.appLocalNotificationHandler();
        alAppLocalNotificationHandler.dataConnectionNotificationHandler();
        
        if (launchOptions != nil) {
            let dictionary = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? NSDictionary
            
            if (dictionary != nil) {
                print("launched from push notification")
                let alPushNotificationService: ALPushNotificationService = ALPushNotificationService()
                
                let appState: NSNumber = NSNumber(integerLiteral: 0)
                let applozicProcessed = alPushNotificationService.processPushNotification(launchOptions,updateUI:appState)
                if (!applozicProcessed) {
                    
                }
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        var deviceTokenString: String = ""
        for i in 0..<deviceToken.count {
            deviceTokenString += String(format: "%02.2hhx", deviceToken[i] as CVarArg)
        }
        if (ALUserDefaultsHandler.getApnDeviceToken() != deviceTokenString) {
            let alRegisterUserClientService: ALRegisterUserClientService = ALRegisterUserClientService()
            alRegisterUserClientService.updateApnDeviceToken(withCompletion: deviceTokenString, withCompletion: { (response, error) in
                
            })
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        print("Received notification :: \(userInfo.description)")
        let alPushNotificationService: ALPushNotificationService = ALPushNotificationService()
        
        let appState: NSNumber = NSNumber(value: 0 as Int32)                 // APP_STATE_INACTIVE
        alPushNotificationService.processPushNotification(userInfo, updateUI: appState)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        print("Received notification With Completion :: \(userInfo.description)")
        let alPushNotificationService: ALPushNotificationService = ALPushNotificationService()
        
        let appState: NSNumber = NSNumber(value: -1 as Int32)                // APP_STATE_BACKGROUND
        alPushNotificationService.processPushNotification(userInfo, updateUI: appState)
        completionHandler(UIBackgroundFetchResult.newData)
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
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "APP_ENTER_IN_BACKGROUND"), object: nil)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        let registerUserClientService = ALRegisterUserClientService()
        registerUserClientService.connect()
        ALPushNotificationService.applicationEntersForeground()
        print("APP_ENTER_IN_FOREGROUND")
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "APP_ENTER_IN_FOREGROUND"), object: nil)
        UIApplication.shared.applicationIconBadgeNumber = 0
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
        return FacebookCore.SDKApplicationDelegate.shared.application(app, open: url, options: options)
    }


}

