//
//  AppDelegate.swift
//  Woojo
//
//  Created by Edouard Goossens on 03/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import LayerKit
import Applozic

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var layerClient: LYRClient
    //var chatManager: ALChatManager
    var isFacebookAuthenticated: Bool = {
        if let fbAuth = FBSDKAccessToken.current() {
            return true
        } else {
            return false
        }
    }()
    
    override init() {
        FIRApp.configure()
        FIRDatabase.database().persistenceEnabled = true
        
        let layerURL = URL(string: "layer:///apps/staging/e5d07d60-a3b7-11e6-bf2c-8858441a5d5e")!
        self.layerClient = LYRClient(appID: layerURL)!
        
        //self.chatManager = ALChatManager(applicationKey: "woojoa4cb24509376f2a59dd5e56caf935bf7")
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        self.layerClient.connect { (success, error) in
            if !success {
                print("Failed to connect to Layer: \(error)")
            } else {
                FIRAuth.auth()?.addStateDidChangeListener { auth, user in
                    if let user = user {
                        print("Signed in user: \(user.uid)")
                        self.authenticateLayer(with: user.uid) { (success, error) in
                            if !success! {
                                print("Failed to authenticate with Layer: \(error)")
                            }
                        }
                    } else {
                        print("No user signed in")
                        self.layerClient.deauthenticate() { (success, error) in
                            if let error = error {
                                print("Failed to deauthenticate Layer \(error)")
                            }
                        }
                        self.window!.rootViewController?.performSegue(withIdentifier: "ShowLogin", sender: self.window!.rootViewController)
                    }
                }
            }
        }
        
        return true
    }
    
    
    func ensureFacebookAuth() {
        if !isFacebookAuthenticated {
            FBSDKAccessToken.refreshCurrentAccessToken { (connection, result, error) in
                if error != nil {
                    print("Error refrehsing FB Token")
                } else {
                    print(result)
                }
            }
        }
    }
    
    func requestIdentityToken(for userID: String, appID: String, nonce: String, completion: @escaping (String?, Error?) -> Void) {
        let identityTokenURL = URL(string: "https://layer-identity-provider.herokuapp.com/identity_tokens")
        var request = URLRequest(url: identityTokenURL!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let parameters = [
            "app_id": appID,
            "user_id": userID,
            "nonce": nonce
        ]
        
        let requestBody = try! JSONSerialization.data(withJSONObject: parameters, options: .init(rawValue: 0))
        request.httpBody = requestBody
        
        let session = URLSession(configuration: URLSessionConfiguration.ephemeral)
        session.dataTask(with: request, completionHandler: { (data, response, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let data = data {
                let responseObject = try! JSONSerialization.jsonObject(with: data, options: .init(rawValue: 0)) as! [String:Any]
                if let error = responseObject["error"] {
                    print("Error getting identityToken \(responseObject["status"]) \(error)")
                    completion(nil, NSError.init(domain: "layer-identity-provider.herokuapp.com", code: responseObject["status"] as! Int, userInfo: nil))
                } else {
                    let identityToken = responseObject["identity_token"] as! String
                    completion(identityToken, nil)
                }
            }
        }).resume()
    }
    
    func authenticationToken(with userID: String, completion: @escaping (Bool?, Error?) -> Void) {
        layerClient.requestAuthenticationNonce() { (nonce, error) in
            if let nonce = nonce {
                self.requestIdentityToken(for: userID, appID: self.layerClient.appID.absoluteString, nonce: nonce) { (identityToken, error) in
                    if let identityToken = identityToken {
                        print("Identity token \(identityToken)")
                        self.layerClient.authenticate(withIdentityToken: identityToken) { (authenticatedUser, error) in
                            if let authenticatedUser = authenticatedUser {
                                completion(true, nil)
                                print("Layer authenticated user as \(authenticatedUser.userID)")
                            } else {
                                completion(false, error)
                            }
                        }
                    } else {
                        completion(false, error)
                        return
                    }
                }
            } else {
                completion(false, error)
                return
            }
        }
    }
    
    func authenticateLayer(with userID: String, completion: @escaping (Bool?, Error?) -> Void) {
        if let authenticatedUser = layerClient.authenticatedUser {
            if userID == authenticatedUser.userID {
                print("Layer authenticated as user \(authenticatedUser.userID)")
                completion(true, nil)
                return
            } else {
                self.layerClient.deauthenticate() { (success, error) in
                    if let error = error {
                        completion(false, error)
                    } else {
                        self.authenticationToken(with: userID) { (success, error) in
                            completion(success, error)
                        }
                    }
                }
            }
        } else {
            self.authenticationToken(with: userID) { (success, error) in
                completion(success, error)
            }
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
    }


}

