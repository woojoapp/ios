//
//  CandidateOverlayView.swift
//  Woojo
//
//  Created by Edouard Goossens on 13/11/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import UIKit
import Koloda

class CandidateOverlayView: OverlayView {
    
    private let leftImageName = "pass"
    private let leftImageColor: UIColor = UIColor(red: 200.0, green: 0.0, blue: 0.0, alpha: 1.0)
    //private let leftBackgroundColor: UIColor = UIColor(red: 200.0, green: 0.0, blue: 0.0, alpha: 1.0)
    private let rightImageName = "like"
    private let rightImageColor: UIColor = UIColor(red: 0.0, green: 135.0, blue: 0.0, alpha: 1.0)
    //private let rightBackgroundColor: UIColor = UIColor(red: 0.0, green: 135.0, blue: 0.0, alpha: 1.0)

    @IBOutlet weak var overlayImageView: UIImageView!
    
    override var overlayState: SwipeResultDirection?  {
        didSet {
            switch overlayState {
            case .left? :
                //backgroundColor = leftBackgroundColor
                if let originalLeftImage = UIImage(named: leftImageName),
                    let originalLeftCGImage = originalLeftImage.cgImage {
                    let rect = CGRect(origin: .zero, size: originalLeftImage.size)
                    UIGraphicsBeginImageContext(rect.size)
                    let context = UIGraphicsGetCurrentContext()
                    context?.clip(to: rect, mask: originalLeftCGImage)
                    context?.setFillColor(leftImageColor.cgColor)
                    context?.fill(rect)
                    if let coloredImage = UIGraphicsGetImageFromCurrentImageContext(),
                        let coloredCGImage = coloredImage.cgImage {
                        UIGraphicsEndImageContext()
                        let flippedImage = UIImage(cgImage: coloredCGImage, scale: 1.0, orientation: UIImageOrientation.downMirrored)
                        overlayImageView.image = flippedImage
                    } else {
                        UIGraphicsEndImageContext()
                    }
                }
            case .right? :
                //backgroundColor = rightBackgroundColor
                if let originalRightImage = UIImage(named: rightImageName),
                    let originalRightCGImage = originalRightImage.cgImage {
                    let rect = CGRect(origin: .zero, size: originalRightImage.size)
                    UIGraphicsBeginImageContext(rect.size)
                    let context = UIGraphicsGetCurrentContext()
                    context?.clip(to: rect, mask: originalRightCGImage)
                    context?.setFillColor(rightImageColor.cgColor)
                    context?.fill(rect)
                    if let coloredImage = UIGraphicsGetImageFromCurrentImageContext(),
                        let coloredCGImage = coloredImage.cgImage {
                        UIGraphicsEndImageContext()
                        let flippedImage = UIImage(cgImage: coloredCGImage, scale: 1.0, orientation: UIImageOrientation.downMirrored)
                        overlayImageView.image = flippedImage
                    } else {
                        UIGraphicsEndImageContext()
                    }
                }
            default:
                overlayImageView.image = nil
            }
        }
    }
    
}
