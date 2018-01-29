//
//  UserChatBannerView.swift
//  Woojo
//
//  Created by Edouard Goossens on 29/01/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import UIKit

class UserChatBannerView: UIView {
    @IBOutlet var view: UIView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var closeButton: UIButton!
    @IBOutlet var actionButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func loadViewFromNib() -> UIView {
        return UINib(nibName: "UserChatBannerView", bundle: Bundle.main).instantiate(withOwner: self, options: nil).first as! UIView
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
        imageView.contentMode = .scaleAspectFit
    }
    
    func load(title: String? = nil, description: String? = nil, image: UIImage? = nil, actionText: String?) {
        titleLabel.text = title
        descriptionLabel.text = description
        imageView.image = image
        actionButton.setTitle(actionText, for: .normal)
        let closeImageView = UIImageView(image: #imageLiteral(resourceName: "close"))
        closeImageView.frame = CGRect(x: closeButton.frame.width/2.0, y: closeButton.frame.height/2.0, width: 10, height: 10)
        closeButton.addSubview(closeImageView)
        view.backgroundColor = UIColor.init(240, green: 240, blue: 240, alpha: 0.5)
        let bottomBorder = CALayer()
        bottomBorder.frame = CGRect(x: 0.0, y: view.frame.height, width: view.frame.width, height: 0.5)
        bottomBorder.backgroundColor = UIColor.lightGray.cgColor
        view.layer.addSublayer(bottomBorder)
        addSubview(view)
    }
}
