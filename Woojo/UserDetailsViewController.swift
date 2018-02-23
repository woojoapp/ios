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
    
    /*enum ButtonsType: String {
        case decide
        case options
    }*/
    
    @IBOutlet weak var optionsButton: DOFavoriteButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var cardView: UserCardView!
    //@IBOutlet weak var photoActivityIndicator: UIActivityIndicatorView!
    
    
    var user: User?
    var commonEventInfos: [User.CommonEventInfo] = []
    //var imageSources: [ImageSource] = []
    //var buttonsType: ButtonsType = .decide
    
    var candidatesViewController: CandidatesViewController?
    var chatViewController: ChatViewController?
    var reachabilityObserver: AnyObject?
    
    /*@IBAction func like() {
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
    }*/
    
    @IBAction func showOptions() {
        optionsButton.select()
        let actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let closeButton = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .default, handler: { (action) -> Void in
            self.dismiss(sender: self)
        })
        let unmatchButton = UIAlertAction(title: NSLocalizedString("Unmatch", comment: ""), style: .destructive, handler: { (action) -> Void in
            let confirmController = UIAlertController(title: NSLocalizedString("Unmatch", comment: ""), message: NSLocalizedString("Confirm unmatch?", comment: ""), preferredStyle: .alert)
            let confirmAction = UIAlertAction(title: NSLocalizedString("Unmatch", comment: ""), style: .destructive, handler: { (_) in
                HUD.show(.labeledProgress(title: NSLocalizedString("Unmatch", comment: ""), subtitle: NSLocalizedString("Unmatching...", comment: "")), onView: self.parent?.view)
                self.user?.unmatch { error in
                    if let error = error {
                        HUD.show(.labeledError(title: NSLocalizedString("Unmatch", comment: ""), subtitle: NSLocalizedString("Failed to unmatch", comment: "")), onView: self.parent?.view)
                        HUD.hide(afterDelay: 1.0)
                    } else {
                        HUD.show(.labeledSuccess(title: NSLocalizedString("Unmatch", comment: ""), subtitle: NSLocalizedString("Unmatched!", comment: "")), onView: self.parent?.view)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                            self.dismiss(sender: self)
                        })
                    }
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
                    if let error = error {
                        HUD.show(.labeledError(title: NSLocalizedString("Unmatch & report", comment: ""), subtitle: NSLocalizedString("Failed to unmatch and report", comment: "")), onView: self.parent?.view)
                        HUD.hide(afterDelay: 1.0)
                    } else {
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
        /*closeButton.layer.masksToBounds = true
        closeButton.layer.cornerRadius = 5.0
        closeButton.layer.backgroundColor = UIColor(colorLiteralRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.5).cgColor
        cardView?.bringSubview(toFront: closeButton)*/
        
        /*switch buttonsType {
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
        }*/
        
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
            //set(button: likeButton, enabled: true)
            //set(button: passButton, enabled: true)
            set(button: optionsButton, enabled: true)
            
        } else {
            //set(button: likeButton, enabled: false)
            //set(button: passButton, enabled: false)
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
