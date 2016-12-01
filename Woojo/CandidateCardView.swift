//
//  CandidateCardView.swift
//  Woojo
//
//  Created by Edouard Goossens on 01/12/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit

class CandidateCardView: UIView {

    var view: UIView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    
    /*required init?(coder aDecoder: NSCoder) {   // 2 - storyboard initializer
        super.init(coder: aDecoder)
        fromNib()   // 5.
    }*/
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func xibSetup() {
        view = loadViewFromNib()
        
        // use bounds not frame or it'll be offset
        view.frame = bounds
        
        // Make the view stretch with containing view
        view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        // Adding custom subview on top of our view (over any custom drawing > see note below)
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 24
        
        layer.shadowRadius = 5
        layer.shadowOpacity = 0.3
        
        addSubview(view)
    }
    
    func loadViewFromNib() -> UIView {
        
        let nib = UINib(nibName: "CandidateCardView", bundle: Bundle.main)
        let v = nib.instantiate(withOwner: self, options: nil).first as! UIView
        
        return v
    }
    
    override init(frame: CGRect) {
        // 1. setup any properties here
        
        // 2. call super.init(frame:)
        super.init(frame: frame)
        
        // 3. Setup view from .xib file
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        // 1. setup any properties here
        
        // 2. call super.init(coder:)
        super.init(coder: aDecoder)
        
        // 3. Setup view from .xib file
        xibSetup()
    }
    
}
