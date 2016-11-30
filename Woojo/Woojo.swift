//
//  Woojoo.swift
//  Woojo
//
//  Created by Edouard Goossens on 28/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation

func woojoError(_ error: String, location: String = "\(#file):\(#line)") -> NSError {
    return NSError(domain: "ExampleError", code: -1, userInfo: [NSLocalizedDescriptionKey: "\(location): \(error)"])
}
