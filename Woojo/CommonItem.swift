//
//  CommonItem.swift
//  Woojo
//
//  Created by Edouard Goossens on 07/11/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import Foundation

protocol CommonItem {
    var id: String { get set }
    var name: String? { get set }
    var pictureURL: URL? { get set }
}
