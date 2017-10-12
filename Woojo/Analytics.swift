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

class Analytics {
    
    static func Log(event name: String, with parameters: [String: String] = [:]) {
        //AppEventsLogger.log(name, parameters: convertToFacebookFormat(parameters: parameters), valueToSum: nil, accessToken: nil)
        //FirebaseAnalytics.Analytics.logEvent(withName: name, parameters: parameters as [String : NSObject])
    }
    
    fileprivate static func convertToFacebookFormat(parameters: [String:String]) -> AppEvent.ParametersDictionary {
        var facebookParameters: AppEvent.ParametersDictionary = [:]
        for (name, value) in parameters {
            facebookParameters[.custom(name)] = value
        }
        return facebookParameters
    }
    
}
