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
import FirebaseMessaging
import Koloda
import RxSwift
import RxCocoa
import DOFavoriteButton
import RPCircularProgress
import Whisper
import SDWebImage
import UserNotifications

class CandidatesViewController: UIViewController {
    
    @IBOutlet weak var kolodaView: KolodaView!
    //@IBOutlet weak var likeButton: DOFavoriteButton!
    //@IBOutlet weak var passButton: DOFavoriteButton!
    @IBOutlet weak var loadingContainerView: UIView!
    @IBOutlet weak var loadingView: RPCircularProgress!
    
    var reachabilityObserver: AnyObject?
    
    var disposeBag = DisposeBag()
    
    var shouldApplyAppearAnimation = true
    var ranOutOfCards = true
    
    let buttonsBackgroundColor = UIColor.black.withAlphaComponent(0.3)
    
    /*@IBAction func likePressed(_ sender: DOFavoriteButton) {
        likeButton.select()
        set(button: passButton, enabled: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            if let uid = User.current.value?.candidates[self.kolodaView.currentCardIndex].uid {
                let analyticsEventParameters = [Constants.Analytics.Events.CandidateLiked.Parameters.uid: uid,
                                                Constants.Analytics.Events.CandidateLiked.Parameters.type: "press",
                                                Constants.Analytics.Events.CandidateLiked.Parameters.screen: String(describing: type(of: self))]
                Analytics.Log(event: Constants.Analytics.Events.CandidateLiked.name, with: analyticsEventParameters)
            }
            self.kolodaView?.swipe(.right)
        })
    }
    
    @IBAction func passPressed(_ sender: DOFavoriteButton) {
        passButton.select()
        set(button: likeButton, enabled: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            if let uid = User.current.value?.candidates[self.kolodaView.currentCardIndex].uid {
                let analyticsEventParameters = [Constants.Analytics.Events.CandidatePassed.Parameters.uid: uid,
                                                Constants.Analytics.Events.CandidatePassed.Parameters.type: "press",
                                                Constants.Analytics.Events.CandidatePassed.Parameters.screen: String(describing: type(of: self))]
                Analytics.Log(event: Constants.Analytics.Events.CandidatePassed.name, with: analyticsEventParameters)
            }
            self.kolodaView?.swipe(.left)
        })
    }*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        User.current.asObservable()
            .subscribe(onNext: { user in
                user?.candidatesDelegate = self                
            }).addDisposableTo(disposeBag)
        
        kolodaView.dataSource = self
        kolodaView.delegate = self
        
        /*likeButton.layer.cornerRadius = likeButton.frame.width / 2
        likeButton.layer.masksToBounds = true
        set(button: likeButton, enabled: false)
        
        passButton.layer.cornerRadius = passButton.frame.width / 2
        passButton.layer.masksToBounds = true
        set(button: passButton, enabled: false)*/
        
        self.view.bringSubview(toFront: kolodaView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.showSettingsButton()
        let settingsButton = self.navigationItem.rightBarButtonItem?.customView as? UIButton
        settingsButton?.addTarget(self, action: #selector(showSettings(sender:)), for: .touchUpInside)
        
        loadingContainerView.layer.borderWidth = 1.0
        loadingContainerView.layer.borderColor = UIColor.lightGray.cgColor
        loadingContainerView.layer.cornerRadius = 24.0
        
        loadingView.layer.borderColor = UIColor.lightGray.cgColor
        loadingView.layer.masksToBounds = true
        loadingView.layer.borderWidth = 1.0
        
        loadingView.enableIndeterminate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startMonitoringReachability()
        checkReachability()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadingView.layer.cornerRadius = loadingView.frame.size.width / 2
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopMonitoringReachability()
    }
    
    func hideKolodaAndShowLoading() {
        kolodaView.isHidden = true
        loadingContainerView.isHidden = false
        //set(button: likeButton, enabled: false)
        //set(button: passButton, enabled: false)
    }
    
    func showKolodaAndHideLoading() {
        kolodaView.isHidden = false
        loadingContainerView.isHidden = true
        //set(button: likeButton, enabled: true)
        //set(button: passButton, enabled: true)
        //likeButton.deselect()
        //passButton.deselect()
    }
    
    /*func set(button: UIButton, enabled: Bool) {
        button.isEnabled = enabled
        button.alpha = (enabled) ? 1.0 : 0.3
    }*/
    
    func showPushNotificationsInvite() {
        let pushNotificationsInvite = UIAlertController(title: "Push notifications", message: "Would you like to get push notifications when you match or receive messages?\n\nYou can also manage this behavior later from the Settings screen.", preferredStyle: .alert)
        pushNotificationsInvite.addAction(UIAlertAction(title: "Yes, notify me", style: .default) { _ in
            Woojo.User.current.value?.activity.setRepliedToPushNotificationsInvite()
            if let application = UIApplication.shared.delegate as? Application {
                application.requestNotifications()
            }
        })
        pushNotificationsInvite.addAction(UIAlertAction(title: "Not now", style: .cancel) { _ in
            Woojo.User.current.value?.activity.setRepliedToPushNotificationsInvite()
        })
        pushNotificationsInvite.popoverPresentationController?.sourceView = self.view
        present(pushNotificationsInvite, animated: true)
    }
    
}

// MARK: - KolodaViewDelegate
    
extension CandidatesViewController: KolodaViewDelegate {
    
    func koloda(_ koloda: KolodaView, didSwipeCardAt index: Int, in direction: SwipeResultDirection) {
        switch direction {
        case .left:
            User.current.value?.candidates[index].pass()
            //if !passButton.isSelected {
                //passButton.select()
                //set(button: likeButton, enabled: false)
                if let uid = User.current.value?.candidates[index].uid {
                    let analyticsEventParameters = [Constants.Analytics.Events.CandidatePassed.Parameters.uid: uid,
                                                    Constants.Analytics.Events.CandidatePassed.Parameters.type: "swipe",
                                                    Constants.Analytics.Events.CandidatePassed.Parameters.screen: String(describing: type(of: self))]
                    Analytics.Log(event: Constants.Analytics.Events.CandidatePassed.name, with: analyticsEventParameters)
                }
            //}
        case .right:
            User.current.value?.candidates[index].like()
            if User.current.value?.activity.repliedToPushNotificationsInvite == nil {
                self.showPushNotificationsInvite()
            }
            //if !likeButton.isSelected {
                //likeButton.select()
                //set(button: passButton, enabled: false)
                if let uid = User.current.value?.candidates[index].uid {
                    let analyticsEventParameters = [Constants.Analytics.Events.CandidateLiked.Parameters.uid: uid,
                                                    Constants.Analytics.Events.CandidateLiked.Parameters.type: "swipe",
                                                    Constants.Analytics.Events.CandidateLiked.Parameters.screen: String(describing: type(of: self))]
                    Analytics.Log(event: Constants.Analytics.Events.CandidateLiked.name, with: analyticsEventParameters)
                }
            //}
        default: break
        }
        /*DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.likeButton.deselect()
            self.passButton.deselect()
            if !self.ranOutOfCards {
                self.set(button: self.likeButton, enabled: true)
                self.set(button: self.passButton, enabled: true)
            }
        })*/
        User.current.value?.candidates.remove(at: index)
        kolodaView.removeCardInIndexRange(index..<index, animated: false)
        kolodaView.currentCardIndex = 0
    }
    
    func kolodaShouldApplyAppearAnimation(_ koloda: KolodaView) -> Bool {
        return shouldApplyAppearAnimation
    }
    
    func kolodaDidRunOutOfCards(_ koloda: KolodaView) {
        ranOutOfCards = true
        Analytics.Log(event: Constants.Analytics.Events.CandidatesDepleted.name)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.hideKolodaAndShowLoading()
        })
    }
    
    func koloda(_ koloda: KolodaView, didShowCardAt index: Int) {
        ranOutOfCards = false
        shouldApplyAppearAnimation = false
    }
    
    func koloda(_ koloda: KolodaView, didSelectCardAt index: Int) {
        /*if let userDetailsViewController = self.storyboard?.instantiateViewController(withIdentifier: "UserDetailsViewController") as? UserDetailsViewController {
            if let candidate = User.current.value?.candidates[index] {
                userDetailsViewController.user = candidate
                userDetailsViewController.candidatesViewController = self
                self.present(userDetailsViewController, animated: true, completion: nil)
                if let uid = User.current.value?.candidates[index].uid {
                    let analyticsEventParameters = [Constants.Analytics.Events.CandidateDetailsDisplayed.Parameters.uid: uid]
                    Analytics.Log(event: Constants.Analytics.Events.CandidateDetailsDisplayed.name, with: analyticsEventParameters)
                }
            }
        }*/
        if let cardView = kolodaView.viewForCard(at: index) as? UserCardView {
            if cardView.isShowingDescription {
                cardView.hideDescription()
            } else {
                cardView.showDescription()
            }
        }
    }

}

// MARK: - KolodaViewDataSource

extension CandidatesViewController: KolodaViewDataSource {
    
    func kolodaNumberOfCards(_ koloda:KolodaView) -> Int {
        return User.current.value?.candidates.count ?? 0
    }
    
    func kolodaSpeedThatCardShouldDrag(_ koloda: KolodaView) -> Koloda.DragSpeed {
        return .fast
    }
    
    func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {
        let cardView = UserCardView(frame: CGRect.zero)
        cardView.setRoundedCornersAndShadow()
        cardView.user = User.current.value?.candidates[index]
        if let commonEventInfos = User.current.value?.candidates[index].commonEventInfos {
            cardView.commonEventInfos = commonEventInfos
        }
        if let commonFriends = User.current.value?.candidates[index].commonFriends {
            print("COMMON FRIENDS \(commonFriends)")
            cardView.commonFriends = commonFriends
        }
        cardView.candidatesViewController = self
        cardView.load {
            self.showKolodaAndHideLoading()
        }
        return cardView
    }
    
    func koloda(koloda: KolodaView, viewForCardOverlayAtIndex index: Int) -> OverlayView? {
        return Bundle.main.loadNibNamed("OverlayView", owner: self, options: nil)?[0] as? OverlayView
    }
    
}

// MARK: - ShowSettingsButton

extension CandidatesViewController: ShowsSettingsButton {
    
    func showSettings(sender : Any?) {
        if let settingsNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "SettingsNavigationController") {
            self.present(settingsNavigationController, animated: true, completion: nil)
        }
    }
    
}

// MARK: - CandidatesDelegate

extension CandidatesViewController: CandidatesDelegate {
    
    func didAddCandidate() {
        kolodaView.reloadData()
    }
    
    func didRemoveCandidate(candidateId: String, index: Int) {
        //kolodaView.reloadData()
        print("REMOVED CANDIDATE \(candidateId) at index \(index), count is \(kolodaView.countOfCards)")
        
        //kolodaView.reloadData()
        kolodaView.removeCardInIndexRange(index..<index, animated: false)
        //kolodaView.currentCardIndex = 0
        kolodaView.resetCurrentCardIndex()
        print("AFTER RESET, count is \(kolodaView.countOfCards)")
        if kolodaView.countOfCards == 0 {
            self.hideKolodaAndShowLoading()
        }
        /*if let candidatesCount = Woojo.User.current.value?.candidates.count, candidatesCount == 0 {
            self.hideKolodaAndShowLoading()
        }*/
    }
    
}

// MARK: - ReachabilityAware

extension CandidatesViewController: ReachabilityAware {
    
    func setReachabilityState(reachable: Bool) {
        if reachable {
            loadingView.progressTintColor = view.tintColor
            if !self.shouldApplyAppearAnimation && !ranOutOfCards {
                showKolodaAndHideLoading()
            }
            if kolodaView.countOfCards == 0 {
                hideKolodaAndShowLoading()
            }
        } else {
            hideKolodaAndShowLoading()
            loadingView.progressTintColor = .white
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
