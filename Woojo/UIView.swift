//
//  UIView.swift
//  Woojo
//
//  Created by Edouard Goossens on 21/05/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import UIKit

extension UIView {
    class func fromNib<T: UIView>() -> T {
        return Bundle.main.loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }
}
