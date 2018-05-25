//
//  MyImageSlideShow.swift
//  Woojo
//
//  Created by Edouard Goossens on 22/05/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import ImageSlideshow

class MyImageSlideShow: ImageSlideshow {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        if let animation = layer.animation(forKey: "position") {
            CATransaction.setAnimationDuration(animation.duration)
            CATransaction.setAnimationTimingFunction(animation.timingFunction)
        } else {
            CATransaction.disableActions()
        }
        for case let gradientLayer as CAGradientLayer in layer.sublayers ?? [] {
            gradientLayer.frame = bounds
            break
        }
        CATransaction.commit()
    }
    
}
