//
//  CandidateDetailsViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 18/12/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import DOFavoriteButton
import ImageSlideshow

class CandidateDetailsViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var carouselView: ImageSlideshow!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var likeButton: DOFavoriteButton!
    @IBOutlet weak var passButton: DOFavoriteButton!
    @IBOutlet weak var closeButton: UIButton!
    
    var candidate: CurrentUser.Candidate?
    var imageSources: [ImageSource] = []
    
    var candidatesViewController: CandidatesViewController?
    
    @IBAction func like() {
        passButton.isHidden = true
        likeButton.backgroundColor = UIColor.white
        likeButton.select()
        self.candidatesViewController?.kolodaView.swipe(.right)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.dismiss(sender: self)
        })
    }
    
    @IBAction func pass() {
        likeButton.isHidden = true
        passButton.backgroundColor = UIColor.white
        passButton.select()
        self.candidatesViewController?.kolodaView.swipe(.left)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.dismiss(sender: self)
        })
    }
    
    @IBAction func dismiss(sender: Any?) {
        self.dismiss(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        carouselView.backgroundColor = UIColor.white
        carouselView.circular = false
        carouselView.pageControlPosition = .custom(padding: 30.0)
        carouselView.pageControl.currentPageIndicatorTintColor = view.tintColor
        carouselView.pageControl.pageIndicatorTintColor = UIColor.lightGray
        carouselView.scrollView.bounces = false
        if let candidate = candidate {
            // Set first photo immediately to avoid flicker
            if let firstPhoto = candidate.profile.photos.value[0], let image = firstPhoto.images[.full] {
                self.imageSources.append(ImageSource(image: image))
                carouselView.setImageInputs(self.imageSources)
                carouselView.pageControl.numberOfPages = candidate.profile.photos.value.flatMap{ $0 }.count
                // Download the others and append
                candidate.profile.downloadAllPhotos(size: .full) {
                    for photo in candidate.profile.photos.value {
                        if let photo = photo, let image = photo.images[.full] {
                            if photo.id == firstPhoto.id { continue }
                            else {
                                self.imageSources.append(ImageSource(image: image))
                            }
                        }
                    }
                    self.carouselView.setImageInputs(self.imageSources)
                }
            }
        }
        carouselView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
        
        if let candidate = candidate, let name = candidate.profile.displayName {
            nameLabel.text = "\(name), \(candidate.profile.age)"
        }
        
        descriptionLabel.text = candidate?.profile.description.value
        
        closeButton.layer.masksToBounds = true
        closeButton.layer.cornerRadius = 5.0
        closeButton.layer.backgroundColor = UIColor(colorLiteralRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.5).cgColor
        carouselView.bringSubview(toFront: closeButton)
        
        self.scrollView.delegate = self
        
        likeButton.layer.cornerRadius = likeButton.frame.width / 2
        likeButton.layer.masksToBounds = true
        
        passButton.layer.cornerRadius = passButton.frame.width / 2
        passButton.layer.masksToBounds = true

        //buttonsView.layer.cornerRadius = 36.0
        //buttonsView.layer.masksToBounds = true
        
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
    
    func didTap(sender: ImageSlideshow) {
        self.dismiss(sender: self)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
 
}
