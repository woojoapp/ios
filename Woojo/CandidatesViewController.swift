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

class CandidatesViewController: TabViewController, KolodaViewDelegate, KolodaViewDataSource, CandidatesDelegate {
    
    @IBOutlet weak var kolodaView: KolodaView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loadingLabel: UILabel!
    
    var shouldApplyAppearAnimation = true
    
    @IBAction func likePressed(_ sender: Any) {
        kolodaView?.swipe(.right)
    }
    
    @IBAction func passPressed(_ sender: Any) {
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
        
        super.setupDataSource()
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
        self.activityIndicator.isHidden = false
        self.loadingLabel.isHidden = false
    }
    
    func showKolodaAndHideLoading() {
        self.kolodaView.isHidden = false
        self.activityIndicator.isHidden = true
        self.loadingLabel.isHidden = true
    }
    
    // MARK: - KolodaViewDelegate
    
    func koloda(_ koloda: KolodaView, didSwipeCardAt index: Int, in direction: SwipeResultDirection) {
        switch direction {
        case .left: User.current.value?.candidates[index].pass()
        case .right: User.current.value?.candidates[index].like()
        default: break
        }
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
    }
    
    // MARK: - KolodaViewDataSource
    
    func kolodaNumberOfCards(_ koloda:KolodaView) -> Int {
        return User.current.value!.candidates.count
    }
    
    /*func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {
        print("Asked for view for card \(index)")
        let imageView = UIImageView()
        if index >= User.current.value?.candidates.count ?? 0 { return imageView }
        DispatchQueue.global(qos: .userInitiated).async {
            User.current.value?.candidates[index].profile?.generatePhotoDownloadURL { url, error in
                if let url = url {
                    do {
                        let image = UIImage(data: try Data(contentsOf: url))
                        DispatchQueue.main.async {
                            imageView.image = image
                            if index == 0 {
                                self.showKolodaAndHideLoading()
                            }
                        }
                    } catch {
                        print("Failed to get candidate image from URL: \(error.localizedDescription)")
                    }
                }
            }
        }
        return imageView
    }*/
    
    func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {
        print("Asked for view for card \(index)")
        if index >= User.current.value?.candidates.count ?? 0 { return UIImageView(image: #imageLiteral(resourceName: "icon_rounded")) }
        let cardView = CandidateCardView(frame: CGRect.zero)
        let candidate = User.current.value?.candidates[index]
        cardView.nameLabel.text = candidate?.profile.displayName
        DispatchQueue.global(qos: .userInitiated).async {
            /*User.current.value?.candidates[index].profile?.generatePhotoDownloadURL { url, error in
                if let url = url {
                    do {
                        let image = UIImage(data: try Data(contentsOf: url))
                        DispatchQueue.main.async {
                            cardView.imageView.image = image
                            if index == 0 {
                                self.showKolodaAndHideLoading()
                            }
                        }
                    } catch {
                        print("Failed to get candidate image from URL: \(error.localizedDescription)")
                    }
                }
            }*/
        }
        return cardView
    }
    
    func koloda(koloda: KolodaView, viewForCardOverlayAtIndex index: Int) -> OverlayView? {
        return Bundle.main.loadNibNamed("OverlayView", owner: self, options: nil)?[0] as? OverlayView
    }

}
