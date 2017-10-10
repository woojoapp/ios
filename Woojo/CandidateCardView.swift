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
    @IBOutlet var firstCommonEventLabel: UILabel!
    @IBOutlet var additionalCommonEventsLabel: UILabel!
    
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
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
}
