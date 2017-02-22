//
//  EventViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 04/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import Koloda
import RxSwift
import RxCocoa
import DOFavoriteButton
import RPCircularProgress

class CandidatesViewController: UIViewController, ShowsSettingsButton, KolodaViewDelegate, KolodaViewDataSource, CandidatesDelegate {
    
    @IBOutlet weak var kolodaView: KolodaView!
    @IBOutlet weak var likeButton: DOFavoriteButton!
    @IBOutlet weak var passButton: DOFavoriteButton!
    @IBOutlet weak var loadingContainerView: UIView!
    @IBOutlet weak var loadingView: RPCircularProgress!
    
    var disposeBag = DisposeBag()
    
    var shouldApplyAppearAnimation = true
    
    @IBAction func likePressed(_ sender: DOFavoriteButton) {
        kolodaView?.swipe(.right)
    }
    
    @IBAction func passPressed(_ sender: DOFavoriteButton) {
        kolodaView?.swipe(.left)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Woojo.User.current.asObservable()
            .subscribe(onNext: { user in
                user?.candidatesDelegate = self
            }).addDisposableTo(disposeBag)
        
        kolodaView.dataSource = self
        kolodaView.delegate = self
        
        self.view.bringSubview(toFront: kolodaView)
        
        self.showSettingsButton()
        let settingsButton = self.navigationItem.rightBarButtonItem?.customView as? UIButton
        settingsButton?.addTarget(self, action: #selector(showSettings(sender:)), for: .touchUpInside)
        
        loadingContainerView.layer.borderWidth = 1.0
        loadingContainerView.layer.borderColor = UIColor.lightGray.cgColor
        loadingContainerView.layer.cornerRadius = 24.0
        
        loadingView.layer.borderColor = UIColor.lightGray.cgColor
        loadingView.layer.cornerRadius = loadingView.frame.size.width / 2
        loadingView.layer.borderWidth = 1.0
        loadingView.enableIndeterminate()
    }
    
    func showSettings(sender : Any?) {
        let settingsNavigationController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SettingsNavigationController")
        self.present(settingsNavigationController, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func didAddCandidate() {
        kolodaView.reloadData()
    }
    
    func hideKolodaAndShowLoading() {
        self.kolodaView.isHidden = true
        self.loadingContainerView.isHidden = false
    }
    
    func showKolodaAndHideLoading() {
        self.kolodaView.isHidden = false
        self.loadingContainerView.isHidden = true
    }
    
    // MARK: - KolodaViewDelegate
    
    func koloda(_ koloda: KolodaView, didSwipeCardAt index: Int, in direction: SwipeResultDirection) {
        switch direction {
        case .left:
            User.current.value?.candidates[index].pass()
            passButton.select()
        case .right:
            User.current.value?.candidates[index].like()
            likeButton.select()
        default: break
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.likeButton.deselect()
            self.passButton.deselect()
        })
        User.current.value?.candidates.remove(at: index)
        kolodaView.removeCardInIndexRange(index..<index, animated: false)
        kolodaView.currentCardIndex = 0
    }
    
    func kolodaShouldApplyAppearAnimation(_ koloda: KolodaView) -> Bool {
        return self.shouldApplyAppearAnimation
    }
    
    func kolodaDidRunOutOfCards(_ koloda: KolodaView) {
        hideKolodaAndShowLoading()
    }
    
    func koloda(_ koloda: KolodaView, didShowCardAt index: Int) {
        self.shouldApplyAppearAnimation = false
    }
    
    func koloda(_ koloda: KolodaView, didSelectCardAt index: Int) {
        print("Clicked on card at index \(index)")
        let userDetailsViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "UserDetailsViewController") as! UserDetailsViewController
        if let candidate = User.current.value?.candidates[index] {
            userDetailsViewController.user = candidate
            userDetailsViewController.candidatesViewController = self
            self.present(userDetailsViewController, animated: true, completion: nil)
        }
    }
    
    // MARK: - KolodaViewDataSource
    
    func kolodaNumberOfCards(_ koloda:KolodaView) -> Int {
        return User.current.value?.candidates.count ?? 0
    }
    
    func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {
        
        print("Asked for view for card \(index)")
        //if index >= User.current.value?.candidates.count ?? 0 { return UIImageView(image: #imageLiteral(resourceName: "icon_rounded")) }
        let cardView = CandidateCardView(frame: CGRect.zero)
        if let candidate = User.current.value?.candidates[index], let name = candidate.profile.displayName {
            cardView.nameLabel.text = "\(name), \(candidate.profile.age)"
            
            func setImage(image: UIImage?) {
                DispatchQueue.main.async {
                    cardView.imageView.image = image
                    if index == 0 {
                        self.showKolodaAndHideLoading()
                    }
                }
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                if let photo = candidate.profile.photos.value[0] {
                    if let fullImage = photo.images[.full] {
                        setImage(image: fullImage)
                    } else {
                        photo.download {
                            setImage(image: photo.images[.full])
                        }
                    }
                } else {
                    print("No photo")
                    self.showKolodaAndHideLoading()
                }
            }
        }
        return cardView
    }

    func koloda(koloda: KolodaView, viewForCardOverlayAtIndex index: Int) -> OverlayView? {
        return Bundle.main.loadNibNamed("OverlayView", owner: self, options: nil)?[0] as? OverlayView
    }

}
