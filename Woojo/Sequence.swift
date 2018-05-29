//
//  Sequence+group.swift
//  Woojo
//
//  Created by Edouard Goossens on 03/04/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import Foundation

public extension Sequence {
    func group<U: Hashable>(by key: (Iterator.Element) -> U) -> [U:[Iterator.Element]] {
        var categories: [U: [Iterator.Element]] = [:]
        for element in self {
            let key = key(element)
            if case nil = categories[key]?.append(element) {
                categories[key] = [element]
            }
        }
        return categories
    }
}
