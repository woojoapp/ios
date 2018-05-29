//
//  EventbriteAPI.OrderResponse.swift
//  Woojo
//
//  Created by Edouard Goossens on 23/02/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import Foundation

extension EventbriteAPI {
    class OrderResponse: Codable {
        var orders: [EventbriteAPI.Order] = []
    }
}
