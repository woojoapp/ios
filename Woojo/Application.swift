//
//  AppDelegate.swift
//  Woojo
//
//  Created by Edouard Goossens on 03/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
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

@UIApplicationMain
class Application: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    var window: UIWindow?
    let loginViewController = LoginViewController(nibName: "LoginViewController", bundle: nil)
    static var remoteConfig: RemoteConfig = RemoteConfig.remoteConfig()
    let disposeBag = DisposeBag()
    static var defferedEvent: Event?
    
    func requestNotifications() {
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func getTopViewController() -> UIViewController? {
        if var topViewController = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = topViewController.presentedViewController {
                if presentedViewController is UIAlertController { break }
                topViewController = presentedViewController
            }
            return topViewController
        } else { return nil }
    }
    
    func navigateToChat(otherUid: String) {
        let topViewController = getTopViewController()
        if let navigationController = topViewController as? NavigationController {
            navigationController.navigationDestination = otherUid
            navigationController.performSegue(withIdentifier: "unwindToMainTabBar", sender: navigationController)
        } else if let topViewController = topViewController as? UserDetailsViewController {
            if let mainTabBarController = topViewController.presentingViewController as? MainTabBarController {
                topViewController.dismiss(sender: nil)
                mainTabBarController.showChatFor(otherUid: otherUid)
            }
        } else if let topViewController = topViewController as? UIImagePickerController,
            let navigationController = topViewController.presentingViewController as? NavigationController {
            navigationController.navigationDestination = otherUid
            navigationController.performSegue(withIdentifier: "unwindToMainTabBar", sender: navigationController)
        } else if let mainTabBarController = topViewController as? MainTabBarController {
            mainTabBarController.showChatFor(otherUid: otherUid)
        }
    }
    
    func navigateToEvents() {
        let topViewController = getTopViewController()
        if let navigationController = topViewController as? NavigationController {
            navigationController.navigationDestination = "events"
            navigationController.performSegue(withIdentifier: "unwindToMainTabBar", sender: navigationController)
        } else if let topViewController = topViewController as? UserDetailsViewController {
            if let mainTabBarController = topViewController.presentingViewController as? MainTabBarController {
                topViewController.dismiss(sender: nil)
                mainTabBarController.showEvents()
            }
        } else if let topViewController = topViewController as? UIImagePickerController,
            let navigationController = topViewController.presentingViewController as? NavigationController {
            navigationController.navigationDestination = "events"
            navigationController.performSegue(withIdentifier: "unwindToMainTabBar", sender: navigationController)
        } else if let mainTabBarController = topViewController as? MainTabBarController {
            if let navigationController = mainTabBarController.selectedViewController as? NavigationController,
                let chatViewController = navigationController.topViewController as? ChatViewController {
                //HUD.flash(.progress, delay: 5.0)
                if let messagesViewController = chatViewController.chatViewDelegate as? MessagesViewController {
                    messagesViewController.showAfterDidAppear = "events"
                }
                navigationController.popViewController(animated: true)
            } else {
                mainTabBarController.showEvents()
            }
        }
    }
    
    func navigateToPeople() {
        let topViewController = getTopViewController()
        if let navigationController = topViewController as? NavigationController {
            navigationController.navigationDestination = "people"
            navigationController.performSegue(withIdentifier: "unwindToMainTabBar", sender: navigationController)
        } else if let topViewController = topViewController as? UserDetailsViewController {
            if let mainTabBarController = topViewController.presentingViewController as? MainTabBarController {
                topViewController.dismiss(sender: nil)
                mainTabBarController.showPeople()
            }
        } else if let topViewController = topViewController as? UIImagePickerController,
            let navigationController = topViewController.presentingViewController as? NavigationController {
            navigationController.navigationDestination = "people"
            navigationController.performSegue(withIdentifier: "unwindToMainTabBar", sender: navigationController)
        } else if let mainTabBarController = topViewController as? MainTabBarController {
            if let navigationController = mainTabBarController.selectedViewController as? NavigationController,
                let chatViewController = navigationController.topViewController as? ChatViewController {
                //HUD.flash(.progress, delay: 5.0)
                if let messagesViewController = chatViewController.chatViewDelegate as? MessagesViewController {
                    messagesViewController.showAfterDidAppear = "people"
                }
                navigationController.popViewController(animated: true)
            } else {
                mainTabBarController.showPeople()
            }
        }
    }
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = true
        AnalyticsConfiguration.shared().setAnalyticsCollectionEnabled(true)
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        let token = Messaging.messaging().fcmToken
        print("FCM token: \(token ?? "")")
        setupRemoteConfig()
        Amplitude.instance().useAdvertisingIdForDeviceId()
        Amplitude.instance().initializeApiKey(Constants.Env.Analytics.amplitudeApiKey)
        
        Whisper.Config.modifyInset = false
        
        // Initialize Facebook SDK
        FacebookCore.SDKApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        Auth.auth().addStateDidChangeListener { auth, user in
            print("AUTH STATE DID CHANGE - LISTENER")
            self.ensureAuthentication(auth: auth, user: user)
        }
        
        if let userInfo = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? NSDictionary {
            if let notificationId = userInfo["notificationId"] as? String {
                HUD.show(.progress, onView: self.window?.rootViewController?.view)
                self.handlePushNotificationTap(notificationId: notificationId, completionHandler: nil)
            }
        }
        
        NotificationCenter.default.addObserver(forName: .AuthStateDidChange, object: Auth.auth(), queue: nil) { notification in
            print("AUTH STATE CHANGED - NOTIFICATION")
            if let auth = notification.object as? Auth,
                let user = auth.currentUser {
                self.ensureAuthentication(auth: auth, user: user)
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
        
        return true
    }
    
    func ensureAuthentication(auth: Auth, user: FirebaseAuth.User?) {
        /* if AccessToken.current == nil {
            print("AUTH STATE DID CHANGE - AccessToken.current == nil", AccessToken.current, user?.uid)
            if self.window?.rootViewController?.presentedViewController != self.loginViewController {
                self.window?.makeKeyAndVisible()
                self.window?.rootViewController?.present(self.loginViewController, animated: true, completion: nil)
            }
        } else if Woojo.User.current.value == nil || (Woojo.User.current.value != nil && !Woojo.User.current.value!.isLoading.value && Woojo.User.current.value!.uid != user?.uid) {
            print("AUTH STATE DID CHANGE - APP DELEGATE 2", Woojo.User.current.value?.uid, user?.uid)
            if let currentUser = CurrentUser() {
                currentUser.load {
                    ALChatManager.shared.setup()
                    Crashlytics.sharedInstance().setUserIdentifier(currentUser.uid)
                    Amplitude.instance().setUserId(currentUser.uid)
                    if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
                        Amplitude.instance().optOut = true
                    }
                    print("AMPLITUDE", Amplitude.instance().getDeviceId(), Amplitude.instance().getSessionId(), Amplitude.instance().userId)
                    print("ONBOARDINGVIEWCONTROLLER", self.loginViewController.onboardingViewController)
                    //self.loginViewController.dismissOnboarding()
                    if let onboardingViewController = self.loginViewController.onboardingViewController {
                        print("DISMISSING ONBOARDING")
                        onboardingViewController.dismiss(animated: true, completion: nil)
                    }
                    self.loginViewController.dismiss(animated: true, completion: {
                        self.loginViewController.setWorking(working: false)
                    })
                }
            } else {
                print("No user signed in", user?.uid)
                let registerUserClientService: ALRegisterUserClientService = ALRegisterUserClientService()
                registerUserClientService.logout { _,_ in
                    
                }
                // Show the login controller
                if self.window?.rootViewController?.presentedViewController != self.loginViewController {
                    self.window?.makeKeyAndVisible()
                    self.window?.rootViewController?.present(self.loginViewController, animated: true, completion: nil)
                }
            }
        } */
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        var deviceTokenString: String = ""
        for i in 0..<deviceToken.count {
            deviceTokenString += String(format: "%02.2hhx", deviceToken[i] as CVarArg)
        }
        if (ALUserDefaultsHandler.getApnDeviceToken() != deviceTokenString) {
            let alRegisterUserClientService = ALRegisterUserClientService()
            alRegisterUserClientService.updateApnDeviceToken(withCompletion: deviceTokenString, withCompletion: { (response, error) in
                
            })
        }
        print("Saving push token", deviceTokenString)
        Messaging.messaging().apnsToken = deviceToken
        if let fcm = Messaging.messaging().fcmToken {
            let device = Device(fcm: fcm, token: deviceTokenString, platform: .iOS)
            Analytics.setUserProperties(properties: ["push_notifications_enabled": "true"])
            Analytics.Log(event: "Preferences_push_notifications", with: ["enabled": "true"])
            UserRepository.shared.addDevice(device: device).catch { _ in print("Failed to set device") }
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
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let notificationId = response.notification.request.content.userInfo["notificationId"] as? String {
            handlePushNotificationTap(notificationId: notificationId, completionHandler: completionHandler)
        }
    }
    
    func handlePushNotificationTap(notificationId: String, completionHandler: (() -> Void)?) {
        HUD.flash(.progress, delay: 10.0) // Show a progress HUD while Firebase synchronises data and retrieves notifications
        /*Woojo.User.current.asObservable().takeWhile({ $0 == nil }).subscribe(onCompleted: {
            Woojo.User.current.value?.notifications.asObservable().takeWhile({ (notifications) -> Bool in
                return !notifications.contains(where: { $0.id == notificationId })
            }).subscribe(onCompleted: {
                let notification = Woojo.User.current.value?.notifications.value.first(where: { $0.id == notificationId })
                if let notification = notification as? CurrentUser.InteractionNotification {
                    Notifier.shared.tapOnNotification(notification: notification)
                } else if let notification = notification as? CurrentUser.EventsNotification {
                    Notifier.shared.tapOnNotification(notification: notification)
                } else if let notification = notification as? CurrentUser.PeopleNotification {
                    Notifier.shared.tapOnNotification(notification: notification)
                }
                completionHandler?()
            }).disposed(by: self.disposeBag)
        }).disposed(by: self.disposeBag)*/
    }
    
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
    }
    
    func application(received remoteMessage: MessagingRemoteMessage) {
        print("Received remote message: \(remoteMessage)")
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
    
    // MARK: - Remote config
    
    func setupRemoteConfig() {
        
        func activateDebugMode() {
            let debugSettings = RemoteConfigSettings(developerModeEnabled: true)
            Application.remoteConfig.configSettings = debugSettings!
        }
        
        let defaults: [String:NSObject] = [
            Constants.App.RemoteConfig.Keys.termsURL:"https://www.woojo.ooo/terms_app.html" as NSObject,
            Constants.App.RemoteConfig.Keys.privacyURL:"https://www.woojo.ooo/privacy_app.html" as NSObject
        ]
        // Change next 2 lines for production
        activateDebugMode()
        let expirationDuration: TimeInterval = 0
        
        Application.remoteConfig.setDefaults(defaults as [String : NSObject]?)
        Application.remoteConfig.fetch(withExpirationDuration: expirationDuration, completionHandler: { status, error in
            print("Remote config", status.rawValue)
            if status == RemoteConfigFetchStatus.success {
                Application.remoteConfig.activateFetched()
            }
            if let error = error {
                print("Failed to fetch remote config: \(error.localizedDescription)")
            }
        })
    }

}

