//
//  Analytics.swift
//  Woojo
//
//  Created by Edouard Goossens on 05/04/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import Foundation
import FacebookCore
import FirebaseAnalytics
import Amplitude_iOS

class CommonAnalytics {
    
    class func Log(event name: String, with parameters: [String: String] = [:]) {
        print("LOGGING", name, parameters)
        logToFirebaseAnalytics(event: name, with: parameters)
        logToAmplitude(event: name, with: parameters)
    }
    
    class func setUserProperties(properties: [String: String]) {
        Amplitude.instance().setUserProperties(properties)
        for (name, value) in properties {
            FirebaseAnalytics.Analytics.setUserProperty(value, forName: name)
        }
    }
    
    static func logToFirebaseAnalytics(event name: String, with parameters: [String: String] = [:]) {
        FirebaseAnalytics.Analytics.logEvent(name, parameters: parameters as [String : NSObject])
    }
    
    static func logToAmplitude(event name: String, with parameters: [String: String] = [:]) {
        Amplitude.instance().logEvent(name, withEventProperties: parameters)
    }
    
    static func addToAmplitudeUserProperty(name: String, value: Int) {
        let identify = AMPIdentify()
        identify.add(name, value: NSNumber(value: value))
        Amplitude.instance().identify(identify)
    }
    
}
