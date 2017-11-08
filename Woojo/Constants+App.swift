//
//  Constants+App.swift
//  Woojo
//
//  Created by Edouard Goossens on 05/04/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import Foundation
import UIKit

extension Constants {
    
    struct App {
        struct RemoteConfig {
            struct Keys {
                static let termsURL = "terms_url"
                static let privacyURL = "privacy_url"
                static let recommendedEventsEnabled = "recommended_events_enabled"
            }
        }
        /*struct Chat {
            static let applozicApplicationId = "11730f77a2a9608dba95cd86d60c498d0"
        }*/
        struct Appearance {
            struct EmptyDatasets {
                static var titleStringAttributes: [String:Any] {
                    get {
                        let paragraphStyle = NSMutableParagraphStyle()
                        paragraphStyle.alignment = .center
                        let attributes = [
                            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 20.0),
                            NSForegroundColorAttributeName: UIColor.lightGray,
                            NSParagraphStyleAttributeName: paragraphStyle
                        ]
                        return attributes
                    }
                }
                static var descriptionStringAttributes: [String:Any] {
                    get {
                        let paragraphStyle = NSMutableParagraphStyle()
                        paragraphStyle.lineBreakMode = .byWordWrapping
                        paragraphStyle.alignment = .center
                        let attributes = [
                            NSFontAttributeName: UIFont.systemFont(ofSize: 13.0),
                            NSForegroundColorAttributeName: UIColor.lightGray,
                            NSParagraphStyleAttributeName: paragraphStyle
                        ]
                        return attributes
                    }
                }
            }
        }
    }
    
}
