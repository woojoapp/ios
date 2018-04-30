//
//  UIImage+desaturate.swift
//  Woojo
//
//  Created by Edouard Goossens on 29/04/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import UIKit

extension UIImage {
    func desaturate() -> UIImage? {
        let ciImage = CIImage(image: self)
        if let output = ciImage?.applyingFilter("CIColorControls", parameters: ["inputSaturation": 0]) {
            return UIImage(ciImage: output)
        }
        return nil
    }
}
