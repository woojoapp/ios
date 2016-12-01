//
//  Woojoo.swift
//  Woojo
//
//  Created by Edouard Goossens on 28/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit

func woojoError(_ error: String, location: String = "\(#file):\(#line)") -> NSError {
    return NSError(domain: "WoojoError", code: -1, userInfo: [NSLocalizedDescriptionKey: "\(location): \(error)"])
}

/*extension UIView {
    @discardableResult   // 1
    func fromNib<T : UIView>() -> T? {   // 2
        let typeString = String(describing: type(of: self))
        print(typeString)
        guard let view = Bundle.main.loadNibNamed(typeString, owner: self, options: nil)?[0] as? T else {    // 3
            // xib not loaded, or it's top view is of the wrong type
            return nil
        }
        self.addSubview(view)     // 4
        view.translatesAutoresizingMaskIntoConstraints = false   // 5
        view.layoutAttachAll(to: self)   // 6
        return view   // 7
    }
    
    func layoutAttachAll(to view: UIView) {
        let topConstraint = NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        let leadingConstraint = NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0)
        let trailingConstraint = NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
        self.addConstraints([topConstraint, bottomConstraint, leadingConstraint, trailingConstraint])
    }
}*/
