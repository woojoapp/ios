//
//  UserDetailsViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 18/12/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import DOFavoriteButton
import ImageSlideshow

class UserDetailsViewController: UIViewController, UIScrollViewDelegate {
    
    enum ButtonsType: String {
        case decide
        case options
    }
    
    @IBOutlet weak var carouselView: ImageSlideshow!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var likeButton: DOFavoriteButton!
    @IBOutlet weak var passButton: DOFavoriteButton!
    @IBOutlet weak var optionsButton: DOFavoriteButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var photoActivityIndicator: UIActivityIndicatorView!
    
    var user: User?
    var imageSources: [ImageSource] = []
    var buttonsType: ButtonsType = .decide
    
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
    
    @IBAction func showOptions() {
        optionsButton.select()
        let actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let unmatchButton = UIAlertAction(title: "Unmatch", style: .destructive, handler: { (action) -> Void in
            print("Unmatching")
        })
        let reportButton = UIAlertAction(title: "Report", style: .default, handler: { (action) -> Void in
            print("Reporting")
        })
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheetController.addAction(unmatchButton)
        actionSheetController.addAction(reportButton)
        actionSheetController.addAction(cancelButton)
        self.present(actionSheetController, animated: true) {
            self.optionsButton.deselect()
        }
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
        
        if let user = user {
            
            func setFirstImageAndDownloadOthers(firstPhoto: User.Profile.Photo) {
                if let firstImage = firstPhoto.images[.full] {
                    self.imageSources.append(ImageSource(image: firstImage))
                    self.carouselView.setImageInputs(self.imageSources)
                    self.photoActivityIndicator.stopAnimating()
                }
                carouselView.pageControl.numberOfPages = user.profile.photos.value.flatMap{ $0 }.count
                // Download the others and append
                user.profile.downloadAllPhotos(size: .full) {
                    for photo in user.profile.photos.value {
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
            
            // Set first photo immediately to avoid flicker
            if let firstPhoto = user.profile.photos.value[0] {
                if firstPhoto.images[.full] != nil {
                    setFirstImageAndDownloadOthers(firstPhoto: firstPhoto)
                } else {
                    firstPhoto.download(size: .full) {
                        setFirstImageAndDownloadOthers(firstPhoto: firstPhoto)
                    }
                }
                
            }
            
        }
        carouselView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
        
        if let user = user, let name = user.profile.displayName {
            nameLabel.text = "\(name), \(user.profile.age)"
        }
        
        descriptionLabel.text = user?.profile.description.value
        
        closeButton.layer.masksToBounds = true
        closeButton.layer.cornerRadius = 5.0
        closeButton.layer.backgroundColor = UIColor(colorLiteralRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.5).cgColor
        carouselView.bringSubview(toFront: closeButton)
        
        self.scrollView.delegate = self
        
        switch buttonsType {
        case .options:
            optionsButton.isHidden = false
            optionsButton.layer.cornerRadius = optionsButton.frame.width / 2
            optionsButton.layer.masksToBounds = true
        default:
            likeButton.isHidden = false
            likeButton.layer.cornerRadius = likeButton.frame.width / 2
            likeButton.layer.masksToBounds = true
            
            passButton.isHidden = false
            passButton.layer.cornerRadius = passButton.frame.width / 2
            passButton.layer.masksToBounds = true
        }
        

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
