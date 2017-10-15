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
import PKHUD

class UserDetailsViewController: UIViewController {
    
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
    var chatViewController: ChatViewController?
    var reachabilityObserver: AnyObject?
    
    @IBAction func like() {
        set(button: passButton, enabled: false)
        candidatesViewController?.likeButton.select() // Required for analytics event type disambiguation
        likeButton.select()
        if let uid = user?.uid {
            let analyticsEventParameters = [Constants.Analytics.Events.CandidateLiked.Parameters.uid: uid,
                                            Constants.Analytics.Events.CandidateLiked.Parameters.type: "press",
                                            Constants.Analytics.Events.CandidateLiked.Parameters.screen: String(describing: type(of: self))]
            Analytics.Log(event: Constants.Analytics.Events.CandidateLiked.name, with: analyticsEventParameters)
        }
        candidatesViewController?.kolodaView.swipe(.right)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.dismiss(sender: self)
        })
    }
    
    @IBAction func pass() {
        set(button: likeButton, enabled: false)
        candidatesViewController?.passButton.select() // Required for analytics event type disambiguation
        passButton.select()
        if let uid = user?.uid {
            let analyticsEventParameters = [Constants.Analytics.Events.CandidatePassed.Parameters.uid: uid,
                                            Constants.Analytics.Events.CandidatePassed.Parameters.type: "press",
                                            Constants.Analytics.Events.CandidatePassed.Parameters.screen: String(describing: type(of: self))]
            Analytics.Log(event: Constants.Analytics.Events.CandidatePassed.name, with: analyticsEventParameters)
        }
        candidatesViewController?.kolodaView.swipe(.left)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.dismiss(sender: self)
        })
    }
    
    @IBAction func showOptions() {
        optionsButton.select()
        let actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let unmatchButton = UIAlertAction(title: "Unmatch", style: .destructive, handler: { (action) -> Void in
            HUD.show(.labeledProgress(title: "Unmatch", subtitle: "Unmatching..."), onView: self.parent?.view)
            self.user?.unmatch { error in
                if let error = error {
                    HUD.show(.labeledError(title: "Unmatch", subtitle: "Failed to unmatch"), onView: self.parent?.view)
                    print("Failed to unmatch", error)
                    HUD.hide(afterDelay: 1.0)
                } else {
                    HUD.show(.labeledSuccess(title: "Unmatch", subtitle: "Unmatched!"), onView: self.parent?.view)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                        self.dismiss(sender: self)
                    })
                }
            }
            // Don't forget to remove images from cache
        })
        let reportButton = UIAlertAction(title: "Unmatch & report", style: .destructive, handler: { (action) -> Void in
            HUD.show(.labeledProgress(title: "Unmatch & report", subtitle: "Unmatching and reporting..."), onView: self.parent?.view)
            self.user?.report(message: nil) { error in
                if let error = error {
                    HUD.show(.labeledError(title: "Unmatch & report", subtitle: "Failed to unmatch and report"), onView: self.parent?.view)
                    print("Failed to unmatch and report", error)
                    HUD.hide(afterDelay: 1.0)
                } else {
                    HUD.show(.labeledSuccess(title: "Unmatch & report", subtitle: "Done!"), onView: self.parent?.view)
                    self.dismiss(sender: self)
                    self.chatViewController?.conversationDeleted()
                }
            }
        })
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheetController.addAction(unmatchButton)
        actionSheetController.addAction(reportButton)
        actionSheetController.addAction(cancelButton)
        self.present(actionSheetController, animated: true) {
            self.optionsButton.deselect()
        }
    }
    
    func set(button: UIButton, enabled: Bool) {
        button.isEnabled = enabled
        button.alpha = (enabled) ? 1.0 : 0.3
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
            
            carouselView.currentPageChanged = { (index) -> () in
                Analytics.Log(event: Constants.Analytics.Events.CandidateDetailsPhotoChanged.name, with: [Constants.Analytics.Events.CandidateDetailsPhotoChanged.Parameters.uid: user.uid])
            }
            
        }
        carouselView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
        
        if let user = user, let name = user.profile.displayName {
            nameLabel.text = "\(name), \(user.profile.age)"
        }
        
        var descriptionString = user?.profile.description.value ?? ""
        if let candidate = user as? CurrentUser.Candidate {
            descriptionString = "\(candidate.commonEventsInfoString)\n\(descriptionString)"
        }
        descriptionLabel.text = descriptionString
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        closeButton.layer.masksToBounds = true
        closeButton.layer.cornerRadius = 5.0
        closeButton.layer.backgroundColor = UIColor(colorLiteralRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.5).cgColor
        carouselView.bringSubview(toFront: closeButton)
        
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
        
        if let user = user {
            if user.uid.range(of: "woojo-") != nil {
                optionsButton.isHidden = true
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startMonitoringReachability()
        checkReachability()
        self.chatViewController?.wireUnmatchObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.chatViewController?.unwireUnmatchObserver()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopMonitoringReachability()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
    }
    
    func didTap(sender: ImageSlideshow) {
        self.dismiss(sender: self)
    }
 
}

// MARK: - ReachabilityAware

extension UserDetailsViewController: ReachabilityAware {
    
    func setReachabilityState(reachable: Bool) {
        if reachable {
            set(button: likeButton, enabled: true)
            set(button: passButton, enabled: true)
            set(button: optionsButton, enabled: true)
            
        } else {
            set(button: likeButton, enabled: false)
            set(button: passButton, enabled: false)
            set(button: optionsButton, enabled: false)
        }
    }
    
    func checkReachability() {
        if let reachable = isReachable() {
            setReachabilityState(reachable: reachable)
        }
    }
    
    func reachabilityChanged(reachable: Bool) {
        setReachabilityState(reachable: reachable)
    }
    
}
