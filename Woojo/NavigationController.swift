//
//  NavigationController.swift
//  Woojo
//
//  Created by Edouard Goossens on 01/03/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import UIKit
import Applozic
import Whisper

class NavigationController: UINavigationController, ReachabilityAware {
    
    var notification: CurrentUser.Notification?
    
    var reachableMessage = Message(title: "Connected", backgroundColor: UIColor(colorLiteralRed: 0.0, green: 150.0/255.0, blue: 0.0, alpha: 0.8))
    var unreachableMessage = Message(title: "No internet connection", backgroundColor: UIColor.red.withAlphaComponent(0.8))
    
    var showingReachableWhisper = false
    var showingUnreachableWhisper = false
    var handlingReachabilityChange = false
    
    //var reachabilityComponent = ReachabilityComponent()
    
   override func viewDidLoad() {
        super.viewDidLoad()
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
        if let reachability = getReachability() {
            if reachability.isReachable() {
                print("CHECK REACHABILITY REACHABLE")
                Whisper.hide(whisperFrom: self, after: 0.0, animate: false)
                self.showingReachableWhisper = false
                self.showingUnreachableWhisper = false
            } else {
                print("CHECK REACHABILITY UNREACHABLE")
                Whisper.show(whisper: unreachableMessage, to: self, action: .present, animate: false)
                showingUnreachableWhisper = true
            }
        }
    }
    
    func reachabilityChanged(reachability: ALReachability) {
        print("REACHABILITY CHANGED HANDLE", handlingReachabilityChange)
        if handlingReachabilityChange { return }
        handlingReachabilityChange = true
        if reachability.isReachable() {
            print("REACHABILITY CHANGED REACHABLE", showingUnreachableWhisper, showingReachableWhisper)
            if showingUnreachableWhisper && !showingReachableWhisper {
                //guard let navigationController = self as? UINavigationController else { return }
                Whisper.hide(whisperFrom: self, after: 0.0, animate: true, completion: {
                    self.showingUnreachableWhisper = false
                    Whisper.show(whisper: self.reachableMessage, to: self, action: .present)
                    self.showingReachableWhisper = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
                        Whisper.hide(whisperFrom: self, after: 0.0, animate: true, completion: {
                            self.showingReachableWhisper = false
                            self.handlingReachabilityChange = false
                        })
                    })
                })
            } else {
                handlingReachabilityChange = false
            }
        } else {
            print("REACHABILITY CHANGED UNREACHABLE", showingUnreachableWhisper, showingReachableWhisper)
            Whisper.show(whisper: unreachableMessage, to: self, action: .present, animate: true, completion: {
                self.handlingReachabilityChange = false
            })
            showingUnreachableWhisper = true
        }
    }
    
    func stoppedMonitoringReachability() {
        showingReachableWhisper = false
        showingUnreachableWhisper = false
        handlingReachabilityChange = false
    }


}
