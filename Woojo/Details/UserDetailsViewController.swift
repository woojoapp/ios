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
import RxSwift

class UserDetailsViewController: UIViewController {
    
    @IBOutlet weak var optionsButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var otherUser: OtherUser?
    var candidatesViewController: CandidatesViewController?
    var chatViewController: ChatViewController?
    var reachabilityObserver: AnyObject?
    var isMatch = false
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "UserDetailsCommonEventTableViewCell", bundle: nil), forCellReuseIdentifier: "detailsCommonEventCell")
        tableView.register(UINib(nibName: "UserDescriptionTableViewCell", bundle: nil), forCellReuseIdentifier: "descriptionCell")
        tableView.register(UINib(nibName: "UserCommonItemsTableViewCell", bundle: nil), forCellReuseIdentifier: "commonItemsCell")
        tableView.delegate = self
        tableView.dataSource = self
        
        observeOtherUser()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        optionsButton.layer.cornerRadius = optionsButton.frame.width / 2
        optionsButton.layer.masksToBounds = true
        
        if let otherUser = otherUser {
            if otherUser.uid.range(of: "woojo-") != nil {
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
    
    @IBAction func dismiss(sender: Any?) {
        self.dismiss(animated: true)
    }
    
    func didTap(sender: ImageSlideshow) {
        self.dismiss(sender: self)
    }
    
    private func observeOtherUser() {
        UserRepository.shared
            .getOtherUserCommonInfo(uid: otherUser?.uid, otherUserKind: .candidate)?
            .subscribe(onNext: { commonInfo in
                print("COMMM", commonInfo)
            })
            .disposed(by: disposeBag)
    }
    
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
                    let otherUser = self.otherUser {
                    User.Match.between(user: currentUser, and: otherUser, completion: { (match) in
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
                            SwipeRepository.shared.removeLike(on: otherUser.uid) { error, _ in
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
                /* self.otherUser?.report(message: nil) { error in
                    if error != nil {
                        HUD.show(.labeledError(title: NSLocalizedString("Unmatch & report", comment: ""), subtitle: NSLocalizedString("Failed to unmatch and report", comment: "")), onView: self.parent?.view)
                        HUD.hide(afterDelay: 1.0)
                    } else {
                        let identify = AMPIdentify()
                        identify.add("report_count", value: NSNumber(value: 1))
                        Amplitude.instance().identify(identify)
                        if let uid = self.otherUser?.uid {
                            Analytics.Log(event: "Core_report", with: ["other_id": uid])
                        }
                        HUD.flash(.labeledSuccess(title: NSLocalizedString("Unmatch & report", comment: ""), subtitle: NSLocalizedString("Done!", comment: "")), onView: self.parent?.view, delay: 2.0, completion: nil)
                        //HUD.show(.labeledSuccess(title: NSLocalizedString("Unmatch & report", comment: ""), subtitle: NSLocalizedString("Done!", comment: "")), onView: self.parent?.view)
                        self.dismiss(sender: self)
                        self.chatViewController?.conversationDeleted()
                    }
                } */
            })
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
            confirmController.addAction(cancelAction)
            confirmController.addAction(confirmAction)
            confirmController.popoverPresentationController?.sourceView = self.view
            self.present(confirmController, animated: true, completion: nil)
        })
        let cancelButton = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
        actionSheetController.addAction(closeButton)
        if isMatch {
            actionSheetController.addAction(unmatchButton)
        }
        actionSheetController.addAction(reportButton)
        actionSheetController.addAction(cancelButton)
        actionSheetController.popoverPresentationController?.sourceView = self.view
        self.present(actionSheetController, animated: true) {
            //self.optionsButton.deselect()
        }
    }
    
 
}

extension UserDetailsViewController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let user = otherUser {
            if section == 0 {
                return user.commonInfo.events.count
            } else if section == 1 {
                if user.profile?.description.value.count == 0 {
                    return 0
                } else {
                    return 1
                }
            } else if section == 2 {
                if user.commonInfo.friends.count == 0 {
                    return 0
                } else {
                    return 1
                }
            } else if section == 3 {
                if user.commonInfo.pageLikes.count == 0 {
                    return 0
                } else {
                    return 1
                }
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let user = otherUser, let name = user.profile?.displayName {
            if section == 0 {
                if user.commonInfo.events.count == 0 {
                    return nil
                } else {
                    return NSLocalizedString("Common Events", comment: "")
                }
            } else if section == 1 {
                if user.profile?.description.value.count == 0 {
                    return nil
                } else {
                    return String(format: NSLocalizedString("About %@", comment: ""), name)
                }
            } else if section == 2 {
                if user.commonInfo.friends.count == 0 {
                    return nil
                } else {
                    return NSLocalizedString("Mutual Friends", comment: "")
                }
            } else if section == 3 {
                if user.commonInfo.pageLikes.count == 0 {
                    return nil
                } else {
                    return NSLocalizedString("Common Interests", comment: "")
                }
            }
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let user = otherUser {
            if indexPath.section == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "detailsCommonEventCell", for: indexPath) as! UserDetailsCommonEventTableViewCell
                let eventId = user.commonInfo.events[indexPath.row].id
                Event.get(for: eventId, completion: { (event) in
                    if let event = event {
                        if let pictureURL = event.pictureURL {
                            self.setImage(pictureURL: pictureURL, cell: cell)
                        } else if let pictureURL = event.coverURL {
                            self.setImage(pictureURL: pictureURL, cell: cell)
                        } else {
                            cell.setDateVisibility(hidden: false)
                        }
                    }
                })
                cell.eventTextLabel.text = getDisplayString(commonEvent: user.commonInfo.commonEvents[indexPath.row])
                return cell
            } else if indexPath.section == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "descriptionCell", for: indexPath)
                cell.textLabel?.text = user.profile?.description.value
                return cell
            } else if indexPath.section == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "commonItemsCell", for: indexPath) as! UserCommonItemsTableViewCell
                cell.items = user.commonInfo.friends
                cell.collectionView.reloadData()
                return cell
            } else if indexPath.section == 3 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "commonItemsCell", for: indexPath) as! UserCommonItemsTableViewCell
                cell.items = user.commonInfo.pageLikes
                cell.collectionView.reloadData()
                return cell
            }
        }
        return tableView.dequeueReusableCell(withIdentifier: "commonEventCell", for: indexPath)
    }
    
    private func setImage(pictureURL: URL, cell: UserDetailsCommonEventTableViewCell) {
        cell.eventImageView.layer.cornerRadius = 8.0
        cell.eventImageView.layer.masksToBounds = true
        cell.eventImageView.sd_setImage(with: pictureURL, placeholderImage: #imageLiteral(resourceName: "placeholder_100x100"))
        cell.setDateVisibility(hidden: true)
    }
    
    private func getDisplayString(commonEvent: CommonEvent) -> String {
        var rsvpString: String
        switch commonEvent.rsvpStatus {
        case .attending:
            rsvpString = String(format: NSLocalizedString("Goes to %@", comment: ""), commonEvent.name!)
        case .unsure:
            rsvpString = String(format: NSLocalizedString("Interested in %@", comment: ""), commonEvent.name!)
        case .notReplied:
            rsvpString = String(format: NSLocalizedString("Invited to %@", comment: ""), commonEvent.name!)
        case .iWasRecommendedOthers:
            rsvpString = String(format: NSLocalizedString("Goes to %@ (recommended for you)", comment: ""), commonEvent.name!)
        case .otherWasRecommendedMine:
            rsvpString = String(format: NSLocalizedString("Goes to events similar to %@", comment: ""), commonEvent.name!)
        }
        return "\(rsvpString)"
    }
}

extension UserDetailsViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let view = view as? UITableViewHeaderFooterView {
            view.textLabel?.font = .boldSystemFont(ofSize: 13.0)
        }
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
    
    func set(button: UIButton, enabled: Bool) {
        button.isEnabled = enabled
        button.alpha = (enabled) ? 1.0 : 0.3
    }
    
}
