//
//  EventbriteLoginView.swift
//  Woojo
//
//  Created by Edouard Goossens on 23/05/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import UIKit

class EventbriteLoginView: UIView {
    var view: UIView!
    
    @IBOutlet weak var webView: UIWebView!
    
    private let viewModel: EventbriteLoginViewModel
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    init(viewModel: EventbriteLoginViewModel) {
        self.viewModel = viewModel
        super.init(frame: CGRect.zero)
        xibSetup()
    }
    
    private func xibSetup() {
        view = R.nib.eventbriteLoginView().instantiate(withOwner: self, options: nil).first as! UIView
        view.frame = bounds
        view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        
        addSubview(view)
    }
}
