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
        addSubview(view)
    }
    
    override var overlayState: SwipeResultDirection?  {
        didSet {
            switch overlayState {
            case .left? :
                view.layer.borderWidth = 5.0
                view.layer.borderColor = leftShadowColor.cgColor
                overlayImageView.image = UIImage(named: leftImageName)
            case .right? :
                view.layer.borderWidth = 5.0
                view.layer.borderColor = rightShadowColor.cgColor
                overlayImageView.image = UIImage(named: rightImageName)
            default:
                overlayImageView.image = nil
            }
        }
    }
    
}
