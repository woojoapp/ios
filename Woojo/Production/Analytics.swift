//
//  Analytics.swift
//  Woojo
//
//  Created by Edouard Goossens on 05/04/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import Foundation
import FacebookCore

class Analytics: CommonAnalytics {
    override class func Log(event name: String, with parameters: [String: String] = [:]) {
        super.Log(event: name, with: parameters)
        logToFacebook(event: name, with: parameters)
    }
    
    override class func setUserProperties(properties: [String: String]) {
        super.setUserProperties(properties: properties)
        AppEventsLogger.updateUserProperties(properties) { (_, _) in
            
        }
    }
    
    static func logToFacebook(event name: String, with parameters: [String: String] = [:]) {
        AppEventsLogger.log(name, parameters: convertToFacebookFormat(parameters: parameters), valueToSum: nil, accessToken: nil)
    }
    
    fileprivate static func convertToFacebookFormat(parameters: [String: String]) -> AppEvent.ParametersDictionary {
        var facebookParameters: AppEvent.ParametersDictionary = [:]
        for (name, value) in parameters {
            facebookParameters[.custom(name)] = value
        }
        return facebookParameters
    }
}
