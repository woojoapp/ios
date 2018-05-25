//
//  NavigationController.swift
//  Woojo
//
//  Created by Edouard Goossens on 01/03/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import UIKit
import Whisper

class NavigationController: UINavigationController, ReachabilityAware {
    
    //var notification: CurrentUser.Notification?
    //var otherUid: String?
    var navigationDestination: String?
    
    var reachableMessage = Message(title: NSLocalizedString("Online", comment: ""), backgroundColor: UIColor(red: 0.0, green: 150.0/255.0, blue: 0.0, alpha: 0.8))
    var unreachableMessage = Message(title: NSLocalizedString("Offline mode", comment: ""))
    
    var showingReachableWhisper = false
    var showingUnreachableWhisper = false
    var handlingReachabilityChange = false
    
    var reachabilityObserver: AnyObject?
    
    //var reachabilityComponent = ReachabilityComponent()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        unreachableMessage.backgroundColor = view.tintColor.withAlphaComponent(0.8)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startMonitoringReachability()
        checkReachability()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopMonitoringReachability()
    }
    
    func checkReachability() {
        if let reachable = isReachable(), reachable {
            print("CHECK REACHABILITY", reachable)
            Whisper.hide(whisperFrom: self, after: 0.0)
            //Whisper.hide(whisperFrom: self, after: 0.0, animate: false)
            showingReachableWhisper = false
            showingUnreachableWhisper = false
        } else {
            print("CHECK REACHABILITY", false)
            //Whisper.show(whisper: unreachableMessage, to: self, action: .present, animate: false)
            Whisper.show(whisper: unreachableMessage, to: self, action: .present)
            showingUnreachableWhisper = true
        }
    }
    
    func reachabilityChanged(reachable: Bool) {
        if handlingReachabilityChange { return }
        handlingReachabilityChange = true
        if reachable {
            print("CHANGE REACHABILITY", reachable, showingUnreachableWhisper, showingReachableWhisper)
            if showingUnreachableWhisper && !showingReachableWhisper {
                //Whisper.hide(whisperFrom: self, after: 0.0, animate: true, completion: {
                Whisper.hide(whisperFrom: self, after: 0.0)
                    self.showingUnreachableWhisper = false
                    Whisper.show(whisper: self.reachableMessage, to: self, action: .present)
                    self.showingReachableWhisper = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
                        //Whisper.hide(whisperFrom: self, after: 0.0, animate: true, completion: {
                        Whisper.hide(whisperFrom: self, after: 0.0)
                            self.showingReachableWhisper = false
                            self.handlingReachabilityChange = false
                        //})
                    })
                //})
            } else {
                handlingReachabilityChange = false
            }
        } else {
            print("CHANGE REACHABILITY", reachable, showingUnreachableWhisper, showingReachableWhisper)
            if !showingUnreachableWhisper {
                //Whisper.show(whisper: unreachableMessage, to: self, action: .present, animate: true, completion: {
                Whisper.show(whisper: unreachableMessage, to: self, action: .present)
                    self.handlingReachabilityChange = false
                //})
                showingUnreachableWhisper = true
            } else {
                handlingReachabilityChange = false
            }
        }
    }
    
    func stoppedMonitoringReachability() {
        showingReachableWhisper = false
        showingUnreachableWhisper = false
        handlingReachabilityChange = false
    }
    
    
}
