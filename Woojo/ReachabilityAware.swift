//
//  ReachabilityDelegate.swift
//  Woojo
//
//  Created by Edouard Goossens on 06/03/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import Applozic

protocol ReachabilityAware: class {
    
    var reachabilityObserver: AnyObject? { get set }
    
    func startMonitoringReachability()
    func startedMonitoringReachability()
    func checkReachability()
    func isReachable() -> Bool?
    func stopMonitoringReachability()
    func stoppedMonitoringReachability()
    func reachabilityChanged(reachable: Bool)
    
}

extension ReachabilityAware where Self: UIViewController {
    
    func startedMonitoringReachability() {
        
    }
    
    func checkReachability() {
        
    }
    
    func isReachable() -> Bool? {
        return ALReachability.forInternetConnection().isReachable()
    }
    
    func startMonitoringReachability() {
        reachabilityObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.AL_kReachabilityChanged, object: nil, queue: nil, using: { notification in
            if let reachability = notification.object as? ALReachability {
                self.reachabilityChanged(reachable: reachability.isReachable())
            }
        })
        startedMonitoringReachability()
    }
    
    func stopMonitoringReachability() {
        if let reachabilityObserver = reachabilityObserver {
            NotificationCenter.default.removeObserver(reachabilityObserver)
            stoppedMonitoringReachability()
        }
    }
    
    func reachabilityChanged(reachable: Bool) {
        
    }
    
    func stoppedMonitoringReachability() {
        
    }
    
}
