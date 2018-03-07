//
//  UserDetailsViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 18/12/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
// import DOFavoriteButton
import ImageSlideshow
import PKHUD
import Amplitude_iOS

class UserDetailsViewController: UIViewController {
    
    @IBOutlet weak var optionsButton: UIButton!
    @IBOutlet weak var cardView: UserCardView!
    
    var user: User?
    var commonEventInfos: [User.CommonEventInfo] = []
    var candidatesViewController: CandidatesViewController?
    var chatViewController: ChatViewController?
    var reachabilityObserver: AnyObject?
    
    @IBAction func showOptions() {
        //optionsButton.select()
        let actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let closeButton = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .default, handler: { (action) -> Void in
            self.dismiss(sender: self)
        })
        let unmatchButton = UIAlertAction(title: NSLocalizedString("Unmatch", comment: ""), style: .destructive, handler: { (action) -> Void in
            let confirmController = UIAlertController(title: NSLocalizedString("Unmatch", comment: ""), message: NSLocalizedString("Confirm unmatch?", comment: ""), preferredStyle: .alert)
            let confirmAction = UIAlertAction(title: NSLocalizedString("Unmatch", comment: ""), style: .destructive, handler: { (_) in
                HUD.show(.labeledProgress(title: NSLocalizedString("Unmatch", comment: ""), subtitle: NSLocalizedString("Unmatching...", comment: "")), onView: self.parent?.view)
                
                // Prepare event logging
                if let currentUser = User.current.value,
                    let user = self.user {
                    User.Match.between(user: currentUser, and: user, completion: { (match) in
                        if match != nil {
                            // Prepare event logging
                            let identify = AMPIdentify()
                            identify.add("unmatch_count", value: NSNumber(value: 1))
                            Amplitude.instance().identify(identify)
                            var parameters: [String: String]?
                            if let commonality = try? currentUser.commonality(match: match!),
                                let bothGoing = try? currentUser.bothGoing(match: match!) {
                                parameters = [
                                    "other_id": match!.on,
                                    "event_commonality": String(commonality),
                                    "has_both_going": String(bothGoing)
                                ]
                            }
                            // Unmatch
                            self.user?.unmatch { error in
                                if error != nil {
                                    HUD.show(.labeledError(title: NSLocalizedString("Unmatch", comment: ""), subtitle: NSLocalizedString("Failed to unmatch", comment: "")), onView: self.parent?.view)
                                    HUD.hide(afterDelay: 1.0)
                                } else {
                                    if parameters != nil {
                                        Analytics.Log(event: "Core_unmatch", with: parameters!)
                                    }
                                    HUD.show(.labeledSuccess(title: NSLocalizedString("Unmatch", comment: ""), subtitle: NSLocalizedString("Unmatched!", comment: "")), onView: self.parent?.view)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                                        self.dismiss(sender: self)
                                    })
                                }
                            }
                        }
                    })
                }
                // Don't forget to remove images from cache
            })
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
            confirmController.addAction(cancelAction)
            confirmController.addAction(confirmAction)
            confirmController.popoverPresentationController?.sourceView = self.view
            self.present(confirmController, animated: true, completion: nil)
        })
        let reportButton = UIAlertAction(title: NSLocalizedString("Unmatch & report", comment: ""), style: .destructive, handler: { (action) -> Void in
            let confirmController = UIAlertController(title: NSLocalizedString("Unmatch & report", comment: ""), message: NSLocalizedString("Confirm unmatch and report?", comment: ""), preferredStyle: .alert)
            let confirmAction = UIAlertAction(title: NSLocalizedString("Unmatch & report", comment: ""), style: .destructive, handler: { (_) in
                HUD.show(.labeledProgress(title: NSLocalizedString("Unmatch & report", comment: ""), subtitle: NSLocalizedString("Unmatching and reporting...", comment: "")), onView: self.parent?.view)
                self.user?.report(message: nil) { error in
                    if error != nil {
                        HUD.show(.labeledError(title: NSLocalizedString("Unmatch & report", comment: ""), subtitle: NSLocalizedString("Failed to unmatch and report", comment: "")), onView: self.parent?.view)
                        HUD.hide(afterDelay: 1.0)
                    } else {
                        let identify = AMPIdentify()
                        identify.add("report_count", value: NSNumber(value: 1))
                        Amplitude.instance().identify(identify)
                        if let uid = self.user?.uid {
                            Analytics.Log(event: "Core_report", with: ["other_id": uid])
                        }
                        HUD.show(.labeledSuccess(title: NSLocalizedString("Unmatch & report", comment: ""), subtitle: NSLocalizedString("Done!", comment: "")), onView: self.parent?.view)
                        self.dismiss(sender: self)
                        self.chatViewController?.conversationDeleted()
                    }
                }
            })
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
            confirmController.addAction(cancelAction)
            confirmController.addAction(confirmAction)
            confirmController.popoverPresentationController?.sourceView = self.view
            self.present(confirmController, animated: true, completion: nil)
        })
        let cancelButton = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
        actionSheetController.addAction(closeButton)
        actionSheetController.addAction(unmatchButton)
        actionSheetController.addAction(reportButton)
        actionSheetController.addAction(cancelButton)
        actionSheetController.popoverPresentationController?.sourceView = self.view
        self.present(actionSheetController, animated: true) {
            //self.optionsButton.deselect()
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
        
        //optionsButton.
        
        cardView.user = self.user
        cardView.commonEventInfos = self.commonEventInfos
        cardView.initiallyShowDescription = true
        cardView.load {
            self.cardView.carouselView.draggingEnabled = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        optionsButton.layer.cornerRadius = optionsButton.frame.width / 2
        optionsButton.layer.masksToBounds = true
        
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
            set(button: optionsButton, enabled: true)
            
        } else {
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
