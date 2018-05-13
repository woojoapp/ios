//
// Created by Edouard Goossens on 12/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import Foundation

extension Optional where Wrapped == String {
    func isNullOrEmpty() -> Bool {
        return self == nil || self!.isEmpty
    }
}