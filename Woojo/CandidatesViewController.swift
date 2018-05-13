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
// import DOFavoriteButton
import RPCircularProgress
import Whisper
import SDWebImage
import UserNotifications
import Crashlytics
import Amplitude_iOS
import BWWalkthrough

class CandidatesViewController: UIViewController {
    
    @IBOutlet weak var kolodaView: KolodaView!
    @IBOutlet weak var loadingContainerView: UIView!
    @IBOutlet weak var loadingView: RPCircularProgress!
    
    var reachabilityObserver: AnyObject?
    var disposeBag = DisposeBag()
    var onboardingViewController: OnboardingViewController?
    private let peopleViewModel = PeopleViewModel.shared
    private var candidates: [Candidate] = []
    private var candidateAddedListenerHandle: UInt?
    private var candidateRemovedListenerHandle: UInt?
    
    var shouldApplyAppearAnimation = true
    var ranOutOfCards = true
    
    let slideNames = [
        "onboarding_post_ok",
        "onboarding_post_about",
        "onboarding_post_photos",
        "onboarding_post_end"
    ]
    private static let REPLIED_TO_PUSH_NOTIFICATIONS_INVITE = "REPLIED_TO_PUSH_NOTIFICATIONS_INVITE"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* User.current.asObservable()
            .subscribe(onNext: { user in
                user?.candidatesDelegate = self                
            }).disposed(by: disposeBag) */
        
        kolodaView.dataSource = self
        kolodaView.delegate = self
        
        let titleImageView = UIImageView(image: #imageLiteral(resourceName: "woojo"))
        titleImageView.contentMode = .scaleAspectFit
        self.navigationItem.titleView = titleImageView
        
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
        loadingView.layer.cornerRadius = loadingView.frame.size.width / 2
        startMonitoringReachability()
        checkReachability()        
        UserRepository.shared.setLastSeen(date: Date()).catch { _ in }
        if !UserDefaults.standard.bool(forKey: "POST_LOGIN_ONBOARDING_COMPLETED") {
            showOnboarding()
        }
    }
    
    func showOnboarding() {
        let onboardingStoryboard = UIStoryboard(name: "Onboarding", bundle: nil)
        if let onboarding = onboardingStoryboard.instantiateViewController(withIdentifier: "Onboarding0") as? OnboardingViewController {
            onboardingViewController = onboarding
            let ok = onboardingStoryboard.instantiateViewController(withIdentifier: "Onboarding_post_ok")
            let about = onboardingStoryboard.instantiateViewController(withIdentifier: "Onboarding_post_about")
            let photos = onboardingStoryboard.instantiateViewController(withIdentifier: "Onboarding_post_photos")
            let end = onboardingStoryboard.instantiateViewController(withIdentifier: "Onboarding_post_end") as! OnboardingPostEndViewController
            end.onboardingViewController = onboardingViewController
            
            onboardingViewController?.delegate = self
            onboardingViewController?.add(viewController:ok)
            onboardingViewController?.add(viewController:about)
            onboardingViewController?.add(viewController:photos)
            onboardingViewController?.add(viewController:end)
            
            self.present(onboarding, animated: true, completion: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadingView.layer.cornerRadius = loadingView.frame.size.width / 2
        //CurrentUser.Notification.deleteAll(type: "people")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopMonitoringReachability()
    }

    private func startListeningToCandidates() {
        candidateAddedListenerHandle = peopleViewModel.getCandidatesQuery().observe(.childAdded) { (dataSnapshot: DataSnapshot) -> Void in
            self.peopleViewModel.getProfile(uid: dataSnapshot.key).then { profile in
                if let profile = profile,
                   let commonInfo = CommonInfo(from: dataSnapshot) {
                    let candidate = Candidate(uid: dataSnapshot.key)
                    candidate.profile = profile
                    candidate.commonInfo = commonInfo
                    if !self.candidates.contains(where: { $0.uid == candidate.uid }) {
                        self.candidates.append(candidate)
                        self.kolodaView.reloadData()
                    }
                }
            }
        }
        candidateRemovedListenerHandle = peopleViewModel.getCandidatesQuery().observe(.childRemoved) { (dataSnapshot: DataSnapshot) -> Void in
            if self.candidates.contains(where: { $0.uid == dataSnapshot.key }) {
                self.resetCards()
            }
        }
    }

    private func stopListeningToCandidates() {
        if let handle = candidateAddedListenerHandle {
            peopleViewModel.getCandidatesQuery().removeObserver(withHandle: handle)
        }
        if let handle = candidateRemovedListenerHandle {
            peopleViewModel.getCandidatesQuery().removeObserver(withHandle: handle)
        }
    }

    private func resetCards() {
        stopListeningToCandidates()
        candidates.removeAll()
        kolodaView.reloadData()
        startListeningToCandidates()
    }
    
    private func hideKolodaAndShowLoading() {
        kolodaView.isHidden = true
        loadingContainerView.isHidden = false
    }
    
    private func showKolodaAndHideLoading() {
        kolodaView.isHidden = false
        loadingContainerView.isHidden = true
    }
    
    private func showPushNotificationsInvite() {
        let pushNotificationsInvite = UIAlertController(title: NSLocalizedString("Push notifications", comment: ""), message: NSLocalizedString("Would you like to get push notifications when you match or receive messages?\n\nYou can also manage this behavior later from the Settings screen.", comment: ""), preferredStyle: .alert)
        pushNotificationsInvite.addAction(UIAlertAction(title: NSLocalizedString("Yes, notify me", comment: ""), style: .default) { _ in
            UserDefaults.standard.set(true, forKey: CandidatesViewController.REPLIED_TO_PUSH_NOTIFICATIONS_INVITE)
            if let application = UIApplication.shared.delegate as? Application {
                application.requestNotifications()
            }
        })
        pushNotificationsInvite.addAction(UIAlertAction(title: NSLocalizedString("Not now", comment: ""), style: .cancel) { _ in
            UserDefaults.standard.set(true, forKey: CandidatesViewController.REPLIED_TO_PUSH_NOTIFICATIONS_INVITE)
        })
        pushNotificationsInvite.popoverPresentationController?.sourceView = self.view
        present(pushNotificationsInvite, animated: true)
    }
    
    @IBAction func share() {
        peopleViewModel.share(from: self)
    }
    
}

// MARK: - KolodaViewDelegate
    
extension CandidatesViewController: KolodaViewDelegate {
    
    func koloda(_ koloda: KolodaView, didSwipeCardAt index: Int, in direction: SwipeResultDirection) {
            let candidate = candidates[index]
            DispatchQueue.global(qos: .background).async {
                let identify = AMPIdentify()
                var parameters: [String: String]?
                if let commonality = try? CommonalityCalculator.shared.commonality(otherUser: candidate),
                    let bothGoing = try? CommonalityCalculator.shared.bothGoing(otherUser: candidate) {
                     parameters = [
                        "other_id": candidate.uid,
                        "event_commonality": String(commonality),
                        "has_common_going": String(bothGoing)
                    ]
                }
                
                switch direction {
                case .left:
                    self.peopleViewModel.pass(uid: candidate.uid).catch { _ in }
                    self.peopleViewModel.remove(uid: candidate.uid).catch { _ in }
                    identify.add("pass_count", value: NSNumber(value: 1))
                    if parameters != nil {
                        Analytics.Log(event: "Core_pass", with: parameters!)
                    }
                case .right:
                    self.peopleViewModel.like(uid: candidate.uid).catch { _ in }
                    self.peopleViewModel.remove(uid: candidate.uid).catch { _ in }
                    if !UserDefaults.standard.bool(forKey: CandidatesViewController.REPLIED_TO_PUSH_NOTIFICATIONS_INVITE) {
                        self.showPushNotificationsInvite()
                    }
                    identify.add("like_count", value: NSNumber(value: 1))
                    if parameters != nil {
                        Analytics.Log(event: "Core_like", with: parameters!)
                    }
                default: break
                }
                
                Amplitude.instance().identify(identify)
            }
            candidates.remove(at: index)
            self.kolodaView.removeCardInIndexRange(index..<index, animated: false)
            self.kolodaView.currentCardIndex = 0
    }
    
    func kolodaShouldApplyAppearAnimation(_ koloda: KolodaView) -> Bool {
        return shouldApplyAppearAnimation
    }
    
    func kolodaDidRunOutOfCards(_ koloda: KolodaView) {
        ranOutOfCards = true
        let identify = AMPIdentify()
        identify.add("candidates_depleted_count", value: NSNumber(value: 1))
        Amplitude.instance().identify(identify)
        Analytics.Log(event: "Core_candidates_depleted")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.hideKolodaAndShowLoading()
        })
    }
    
    func koloda(_ koloda: KolodaView, didShowCardAt index: Int) {
        ranOutOfCards = false
        shouldApplyAppearAnimation = false
    }
    
    func koloda(_ koloda: KolodaView, didSelectCardAt index: Int) {
        if let userDetailsViewController = self.storyboard?.instantiateViewController(withIdentifier: "UserDetailsViewController") as? UserDetailsViewController {
            userDetailsViewController.otherUser = candidates[index]
            userDetailsViewController.candidatesViewController = self
            self.present(userDetailsViewController, animated: true, completion: nil)
            let analyticsEventParameters = [Constants.Analytics.Events.CandidateDetailsDisplayed.Parameters.uid: candidates[index].uid]
            Analytics.Log(event: Constants.Analytics.Events.CandidateDetailsDisplayed.name, with: analyticsEventParameters)
        }
    }

}

// MARK: - KolodaViewDataSource

extension CandidatesViewController: KolodaViewDataSource {
    
    func kolodaNumberOfCards(_ koloda:KolodaView) -> Int {
        return candidates.count ?? 0
    }
    
    func kolodaSpeedThatCardShouldDrag(_ koloda: KolodaView) -> Koloda.DragSpeed {
        return .fast
    }
    
    func koloda(_ koloda: KolodaView, allowedDirectionsForIndex index: Int) -> [SwipeResultDirection] {
        return [SwipeResultDirection.left, SwipeResultDirection.right]
    }
    
    func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {
        print("CandidatesViewController viewForCardAt", index, "count", candidates.count)
        // let cardView = UserCardView(frame: CGRect.zero)
        let cardView = NewUserCardView(frame: CGRect.zero)
        cardView.setRoundedCornersAndShadow()
        if candidates.count > index {
            cardView.user = candidates[index]
            /* cardView.commonEventInfos = candidates[index].commonInfo.commonEvents.sorted(by: {
                CommonalityCalculator.shared.interestScale(rsvpStatus: $0.rsvpStatus) > CommonalityCalculator.shared.interestScale(rsvpStatus: $1.rsvpStatus)
            })
            cardView.commonFriends = candidates[index].commonInfo.friends
            cardView.commonPageLikes = candidates[index].commonInfo.pageLikes */
        }
        // cardView.candidatesViewController = self
        
        cardView.load {
            self.showKolodaAndHideLoading()
        }
        return cardView
    }
    
    func koloda(_ koloda: KolodaView, viewForCardOverlayAt index: Int) -> OverlayView? {
        let overlayView = CandidateOverlayView(frame: CGRect.zero)
        overlayView.setRoundedCornersAndShadow()
        overlayView.load()
        return overlayView
    }
    
}

// MARK: - ShowSettingsButton

extension CandidatesViewController: ShowsSettingsButton {
    
    @objc func showSettings(sender : Any?) {
        if let settingsNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "SettingsNavigationController") {
            self.present(settingsNavigationController, animated: true, completion: nil)
        }
    }
    
}

// MARK: - CandidatesDelegate

/* extension CandidatesViewController: CandidatesDelegate {
    
    func didAddCandidate() {
        //DispatchQueue.global(qos: .background).async {
        print("DID ADD CANDIDATE")
            self.kolodaView.reloadData()
        //}
    }
    
    func didRemoveCandidate(candidateId: String, index: Int) {
        //kolodaView.reloadData()
        print("CandidatesViewController REMOVED CANDIDATE \(candidateId) at index \(index), count is \(kolodaView.countOfCards)")
        
        //kolodaView.reloadData()
        if let cardView = kolodaView.viewForCard(at: index) as? UserCardView,
            let cardUserId = cardView.user?.uid,
            cardUserId == candidateId {
            print("CandidatesViewController REMOVE CARD FOR USER", candidateId, "CARD HAS", cardView.user?.uid, "AT INDEX", index)
            kolodaView.removeCardInIndexRange(index..<index, animated: false)
            kolodaView.resetCurrentCardIndex()
            print("CandidatesViewController AFTER RESET, count is \(kolodaView.countOfCards)")
        }
        //kolodaView.currentCardIndex = 0
        if kolodaView.countOfCards == 0 {
            self.hideKolodaAndShowLoading()
        }
        /*if let candidatesCount = Woojo.User.current.value?.candidates.count, candidatesCount == 0 {
            self.hideKolodaAndShowLoading()
        }*/
    }
    
} */

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

// MARK: - BWWalkthroughViewControllerDelegate

extension CandidatesViewController: BWWalkthroughViewControllerDelegate {
    func walkthroughPageDidChange(_ pageNumber: Int) {
        onboardingViewController?.showCloseButton(show: pageNumber == slideNames.count - 1)
        let parameters = ["slide_name": slideNames[pageNumber]]
        Analytics.Log(event: "Onboarding_view_slide", with: parameters)
    }
    
    func walkthroughCloseButtonPressed() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(true, forKey: "POST_LOGIN_ONBOARDING_COMPLETED")
        userDefaults.synchronize()
        Analytics.setUserProperties(properties: ["post_login_onboarded": "true"])
        Analytics.Log(event: "Onboarding_post_complete")
        onboardingViewController?.dismiss(animated: true, completion: nil)
    }
}
