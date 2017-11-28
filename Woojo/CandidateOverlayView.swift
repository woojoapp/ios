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
    
    private let leftImageName = "overlay_transparent"
    private let rightImageName = "overlay_transparent"
    private let leftShadowColor = UIColor(red: 255.0, green: 0.0, blue: 0.0, alpha: 1.0)
    private let rightShadowColor = UIColor(red: 0.0, green: 255.0, blue: 0.0, alpha: 1.0)
    @IBOutlet weak var overlayImageView: UIImageView!
    
    var view: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func loadViewFromNib() -> UIView {
        return UINib(nibName: "CandidateOverlayView", bundle: Bundle.main).instantiate(withOwner: self, options: nil).first as! UIView
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    func xibSetup() {
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
    }
    
    func setRoundedCornersAndShadow() {
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 24
        layer.shadowRadius = 5
        layer.shadowOpacity = 0.3
    }
    
    func load() {
        //backgroundColor = UIColor(red: 255.0, green: 255.0, blue: 255.0, alpha: 0.2)
        addSubview(view)
    }
    
    override var overlayState: SwipeResultDirection?  {
        didSet {
            switch overlayState {
            case .left? :
                view.layer.borderWidth = 5.0
                view.layer.borderColor = leftShadowColor.cgColor
                /*rightOverlayImageView.image = nil
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
                        leftOverlayImageView.image = flippedImage
                    } else {
                        UIGraphicsEndImageContext()
                    }
                }*/
                overlayImageView.image = UIImage(named: leftImageName)
            case .right? :
                //layer.shadowColor = rightShadowColor.cgColor
                view.layer.borderWidth = 5.0
                view.layer.borderColor = rightShadowColor.cgColor
                /*leftOverlayImageView.image = nil
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
                        rightOverlayImageView.image = flippedImage
                    } else {
                        UIGraphicsEndImageContext()
                    }
                }*/
                overlayImageView.image = UIImage(named: rightImageName)
            default:
                overlayImageView.image = nil
            }
        }
    }
    
}
