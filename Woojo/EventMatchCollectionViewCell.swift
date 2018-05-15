//
//  EventMatchCollectionViewCell.swift
//  Woojo
//
//  Created by Edouard Goossens on 14/11/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import UIKit
import RxSwift

class EventMatchCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    private var disposeBag = DisposeBag()
    
    var user: User? {
        didSet {
            populate(with: user)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func populate(with user: User?) {
        if let user = user {
            label.text = user.profile?.firstName
            imageView.layer.cornerRadius = imageView.frame.width / 2.0
            imageView.layer.masksToBounds = true
            UserProfileRepository.shared.getPhoto(position: 0, size: .thumbnail).subscribe(onNext: { storageReference in
                if let storageReference = storageReference {
                    self.imageView.sd_setImage(with: storageReference, placeholderImage: #imageLiteral(resourceName: "placeholder_40x40"))
                    self.setNeedsLayout()
                }
            }, onError: { _ in
                
            }).disposed(by: disposeBag)
        }
    }
}
