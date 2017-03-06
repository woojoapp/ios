//
//  ReachabilityDelegate.swift
//  Woojo
//
//  Created by Edouard Goossens on 06/03/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import Whisper
import Applozic

/*struct ReachabilityComponent {
    var reachableMessage = Message(title: "Connected", backgroundColor: UIColor(colorLiteralRed: 0.0, green: 150.0/255.0, blue: 0.0, alpha: 0.8))
    var unreachableMessage = Message(title: "No internet connection", backgroundColor: UIColor.red.withAlphaComponent(0.8))
    
    var showingReachableWhisper = false
    var showingUnreachableWhisper = false
    var handlingReachabilityChange = false
}

protocol HasReachabilityComponent: class {
    var reachabilityComponent: ReachabilityComponent { get set }
}*/

protocol ReachabilityAware: class {
    
    func startMonitoringReachability()
    func startedMonitoringReachability()
    func getReachability() -> ALReachability?
    func stopMonitoringReachability()
    func stoppedMonitoringReachability()
    func reachabilityChanged(reachability: ALReachability)
    
}

extension ReachabilityAware where Self: UIViewController {
    
    /*var reachableMessage: Message { get }
    var unreachableMessage: Message { get }
    
    var showingReachableWhisper: Bool { get set }
    var showingUnreachableWhisper: Bool { get set }
    var handlingReachabilityChange: Bool { get set }*/
    
    /*var reachableMessage: Message {
        return reachabilityComponent.reachableMessage
    }
    var unreachableMessage: Message {
        return reachabilityComponent.unreachableMessage
    }
    
    var showingReachableWhisper: Bool  {
        get { return reachabilityComponent.showingReachableWhisper }
        set { reachabilityComponent.showingReachableWhisper = newValue }
    }
    var showingUnreachableWhisper: Bool {
        get { return reachabilityComponent.showingUnreachableWhisper }
        set { reachabilityComponent.showingUnreachableWhisper = newValue }
    }
    var handlingReachabilityChange: Bool {
        get { return reachabilityComponent.handlingReachabilityChange }
        set { reachabilityComponent.handlingReachabilityChange = newValue }
    }*/
    
    func startedMonitoringReachability() {
        
    }
    
    func getReachability() -> ALReachability? {
        return ALReachability.forInternetConnection()
    }
    
    func startMonitoringReachability() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AL_kReachabilityChanged, object: nil, queue: nil, using: { notification in
            if let reachability = notification.object as? ALReachability {
                self.reachabilityChanged(reachability: reachability)
            }
        })
        startedMonitoringReachability()
        //NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChangedNotificationReceived(notification:)), name: , object: nil)
    }
    
    /*func reachabilityChangedNotificationReceived(notification: Notification) {
        
    }*/
    
        
    func stopMonitoringReachability() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AL_kReachabilityChanged, object: nil)
        stoppedMonitoringReachability()
    }
    
    func stoppedMonitoringReachability() {
        
    }
    
}
