//
//  CandidateDetailsViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 18/12/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import TGLParallaxCarousel

class CandidateDetailsViewController: UIViewController {
    
    @IBOutlet weak var carouselView: TGLParallaxCarousel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var passButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    
    var candidate: CurrentUser.Candidate?
    var photos: [User.Profile.Photo] = []
    
    @IBAction func like() {
        candidate?.like()
        dismiss(sender: self)
    }
    
    @IBAction func pass() {
        candidate?.pass()
        dismiss(sender: self)
    }
    
    @IBAction func dismiss(sender: Any?) {
        self.dismiss(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let profilePhotos = candidate?.profile.photos.value {
            photos = profilePhotos.flatMap{ $0 }
        }
        carouselView.delegate = self
        carouselView.margin = 10.0
        carouselView.type = .normal
        
        nameLabel.text = candidate?.profile.displayName
        descriptionTextView.text = candidate?.profile.description.value
        closeButton.layer.masksToBounds = true
        closeButton.layer.cornerRadius = 5.0
        closeButton.layer.backgroundColor = UIColor(colorLiteralRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.5).cgColor
        carouselView.bringSubview(toFront: closeButton)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
    }
    
    //override var status

}

extension CandidateDetailsViewController: TGLParallaxCarouselDelegate {
    
    func numberOfItemsInCarouselView(_ carouselView: TGLParallaxCarousel) -> Int {
        return photos.count
    }
    
    func carouselView(_ carouselView: TGLParallaxCarousel, itemForRowAtIndex index: Int) -> TGLParallaxCarouselItem {
        let imageFrame = CGRect(x: 0, y: 0, width: carouselView.frame.width, height: carouselView.frame.height - 37)
        let item = TGLParallaxCarouselItem(frame: imageFrame)
        let imageView = UIImageView(frame: imageFrame)
        // Immediately sets images for already downloaded photos
        if let image = self.photos[index].images[.full] {
            imageView.image = image
        } else {
            // Download image if necessary
            photos[index].download(size: .full) {
                if let image = self.photos[index].images[.full] {
                    imageView.image = image
                }
            }
        }
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 10.0
        item.addSubview(imageView)
        return item
    }
    
    func carouselView(_ carouselView: TGLParallaxCarousel, didSelectItemAtIndex index: Int) {
        print("Tap on item at index \(index)")
    }
    
    func carouselView(_ carouselView: TGLParallaxCarousel, willDisplayItem item: TGLParallaxCarouselItem, forIndex index: Int) {
        
    }
    
}
