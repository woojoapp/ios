//
//  Airline.swift
//  Woojo
//
//  Created by Edouard Goossens on 26/01/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import Foundation

public class Airline {
    var iataCode: String
    var name: String
    
    init(iataCode: String, name: String) {
        self.iataCode = iataCode
        self.name = name
    }
}
