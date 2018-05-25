//
//  UserDetailsViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 18/12/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
// import DOFavoriteButton
import FirebaseAuth
import FirebaseStorage
import ImageSlideshow
import PKHUD
import Amplitude_iOS
import RxSwift
import RxCocoa

class UserDetailsViewController<T: User>: UIViewController, AuthStateAware {
    
    
    //@IBOutlet weak var optionsButton: UIButton!
    //@IBOutlet weak var tableView: UITableView!
    
    init(uid: String, userType: T.Type) {
        self.uid = uid
        self.userType = userType
        self.viewModel = UserDetailsViewModel<T>(uid: uid, userType: userType)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    var userDetailsView: UserDetailsView<T>! {
        return self.view as! UserDetailsView<T>
    }
    var viewModel: UserDetailsViewModel<T>
    var uid: String
    //var otherUserId: String!
    var userType: T.Type
    //var otherUser: OtherUser?
    //var candidatesViewController: CandidatesViewController?
    var chatViewController: ChatViewController?
    //let peopleViewModel = PeopleViewModel.shared
    var reachabilityObserver: AnyObject?
    //var isMatch = false
    let disposeBag = DisposeBag()
    var authStateDidChangeListenerHandle: AuthStateDidChangeListenerHandle?
    
    override func loadView() {
        view = UserDetailsView<T>(viewModel: viewModel)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: R.image.options(), style: UIBarButtonItemStyle.plain, target: self, action: #selector(showOptions))
        
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor:UIColor.black]
        
        viewModel.firstName.drive(navigationItem.rx.title).disposed(by: disposeBag)
        viewModel.loaded.drive(onNext: { loaded in
            print("LLOADED", loaded)
        }).disposed(by: disposeBag)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startListeningForAuthStateChange()
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
        stopListeningForAuthStateChange()
    }
    
    /* override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
    } */
    
    private func bindViewModel() {
        
    }
    
    @IBAction func dismiss(sender: Any?) {
        if let navigationController = navigationController {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    /* func didTap(sender: ImageSlideshow) {
        self.dismiss(sender: self)
    }
    
    private func observeUser() {
        /* peopleViewModel.getOtherUser(uid: otherUserId, otherUserType: T.self)
                .subscribe(onNext: { otherUser in
                    if let otherUser = otherUser {
                        //self.otherUser = otherUser
                        self.userDetailsView?.tableView.reloadData()
                    }
                }, onError: { _ in

                }).disposed(by: disposeBag) */
    } */
    
    @objc func showOptions() {
        let actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let closeButton = UIAlertAction(title: R.string.localizable.close(), style: .default, handler: { (action) -> Void in
            self.dismiss(sender: self)
        })
        let unmatchButton = UIAlertAction(title: R.string.localizable.unmatch(), style: .destructive, handler: { (action) -> Void in
            let confirmController = UIAlertController(title: R.string.localizable.unmatch(), message: R.string.localizable.confirmUnmatch(), preferredStyle: .alert)
            let confirmAction = UIAlertAction(title: R.string.localizable.unmatch(), style: .destructive, handler: { _ in self.unmatch() })
            let cancelAction = UIAlertAction(title: R.string.localizable.cancel(), style: .cancel, handler: nil)
            confirmController.addAction(cancelAction)
            confirmController.addAction(confirmAction)
            confirmController.popoverPresentationController?.sourceView = self.view
            self.present(confirmController, animated: true, completion: nil)
        })
        let reportButton = UIAlertAction(title: R.string.localizable.unmatchAndReport(), style: .destructive, handler: { (action) -> Void in
            let confirmController = UIAlertController(title: R.string.localizable.unmatchAndReport(), message: R.string.localizable.confirmUnmatchAndReport(), preferredStyle: .alert)
            let confirmAction = UIAlertAction(title: R.string.localizable.unmatchAndReport(), style: .destructive, handler: { _ in self.report() })
            let cancelAction = UIAlertAction(title: R.string.localizable.cancel(), style: .cancel, handler: nil)
            confirmController.addAction(cancelAction)
            confirmController.addAction(confirmAction)
            confirmController.popoverPresentationController?.sourceView = self.view
            self.present(confirmController, animated: true, completion: nil)
        })
        let cancelButton = UIAlertAction(title: R.string.localizable.cancel(), style: .cancel, handler: nil)
        actionSheetController.addAction(closeButton)
        if userType is Match.Type {
            actionSheetController.addAction(unmatchButton)
        }
        if userType is OtherUser.Type {
            actionSheetController.addAction(reportButton)
        }
        actionSheetController.addAction(cancelButton)
        actionSheetController.popoverPresentationController?.sourceView = self.view
        self.present(actionSheetController, animated: true)
    }
    
    private func unmatch() {
        HUD.show(.labeledProgress(title: R.string.localizable.unmatch(), subtitle: R.string.localizable.unmatching()), onView: self.parent?.view)
        // Prepare event logging
        let identify = AMPIdentify()
        identify.add("unmatch_count", value: NSNumber(value: 1))
        Amplitude.instance().identify(identify)
        var parameters: [String: String]?
        //if let commonality = try? CommonalityCalculator.shared.commonality(otherUser: match!),
        //    let bothGoing = try? CommonalityCalculator.shared.bothGoing(otherUser: match!) {
            parameters = [
                "other_id": uid//,
                //"event_commonality": String(commonality),
                //"has_both_going": String(bothGoing)
            ]
        //}
        // Unmatch
        viewModel.unmatch().then {
            if parameters != nil {
                Analytics.Log(event: "Core_unmatch", with: parameters!)
            }
            HUD.show(.labeledSuccess(title: NSLocalizedString("Unmatch", comment: ""), subtitle: NSLocalizedString("Unmatched!", comment: "")), onView: self.parent?.view)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                self.dismiss(sender: self)
            })
        }.catch { _ in
            HUD.show(.labeledError(title: NSLocalizedString("Unmatch", comment: ""), subtitle: NSLocalizedString("Failed to unmatch", comment: "")), onView: self.parent?.view)
            HUD.hide(afterDelay: 1.0)
        }
    }
    
    private func report() {
        HUD.show(.labeledProgress(title: R.string.localizable.unmatchAndReport(), subtitle: R.string.localizable.unmatchingAndReporting()), onView: self.parent?.view)
        viewModel.report(message: nil).then {
            let identify = AMPIdentify()
            identify.add("report_count", value: NSNumber(value: 1))
            Amplitude.instance().identify(identify)
            Analytics.Log(event: "Core_report", with: ["other_id": self.uid])
            HUD.flash(.labeledSuccess(title: R.string.localizable.unmatchAndReport(), subtitle: R.string.localizable.done()), onView: self.parent?.view, delay: 2.0, completion: nil)
            self.dismiss(sender: self)
            self.chatViewController?.conversationDeleted()
        }.catch { _ in
            HUD.show(.labeledError(title: R.string.localizable.unmatchAndReport(), subtitle: R.string.localizable.failedToUnmatchAndReport()), onView: self.parent?.view)
            HUD.hide(afterDelay: 1.0)
        }
    }

    /*func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let user = otherUser {
            if section == 0 {
                return user.commonInfo.events.count
            } else if section == 1 {
                if user.profile?.description != nil {
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
        if let user = otherUser, let name = user.profile?.firstName {
            if section == 0 {
                if user.commonInfo.events.count == 0 {
                    return nil
                } else {
                    return NSLocalizedString("Common Events", comment: "")
                }
            } else if section == 1 {
                if user.profile?.description != nil {
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
                if let eventId = Array(user.commonInfo.events.values)[indexPath.row].id {
                    EventRepository.shared.get(eventId: eventId).toPromise().then { event in
                        if let event = event {
                            if let urlString = event.pictureURL,
                                let pictureURL = URL(string: urlString) {
                                self.setImage(pictureURL: pictureURL, cell: cell)
                            } else if let urlString = event.coverURL,
                                let pictureURL = URL(string: urlString) {
                                self.setImage(pictureURL: pictureURL, cell: cell)
                            } else {
                                cell.setDateVisibility(hidden: false)
                            }
                        }
                    }
                }
                cell.eventTextLabel.text = getDisplayString(commonEvent: Array(user.commonInfo.commonEvents.values)[indexPath.row])
                return cell
            } else if indexPath.section == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "descriptionCell", for: indexPath)
                cell.textLabel?.text = user.profile?.description
                return cell
            } else if indexPath.section == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "commonItemsCell", for: indexPath) as! UserCommonItemsTableViewCell
                cell.items = Array(user.commonInfo.friends.values)
                cell.collectionView.reloadData()
                return cell
            } else if indexPath.section == 3 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "commonItemsCell", for: indexPath) as! UserCommonItemsTableViewCell
                cell.items = Array(user.commonInfo.pageLikes.values)
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

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let view = view as? UITableViewHeaderFooterView {
            view.textLabel?.font = .boldSystemFont(ofSize: 13.0)
        }
    } */
}

// MARK: - UserDetailsViewDataSource

/* extension UserDetailsViewController: UserDetailsViewDataSource {
    func firstName() -> Driver<String?> {
        return viewModel.firstName
    }
    
    func nameAge() -> Driver<String?> {
        return viewModel.nameAge
    }
    
    func city() -> Driver<String?> {
        return viewModel.city
    }
    
    func occupation() -> Driver<String?> {
        return viewModel.occupation
    }
    
    func pictures() -> Driver<[Int: StorageReference]> {
        return viewModel.photos
    }
    
    func description() -> Driver<String?> {
        return viewModel.description
    }
    
    func events() -> Driver<[Event]> {
        return viewModel.events
    }
    
    func friends() -> Driver<[User]> {
        return viewModel.friends
    }
    
    func pageLikes() -> Driver<[PageLike]> {
        return viewModel.pageLikes
    }
} */

// MARK: - ReachabilityAware

extension UserDetailsViewController: ReachabilityAware {
    func setReachabilityState(reachable: Bool) {
        if reachable {
            navigationItem.rightBarButtonItem?.isEnabled = true
            
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = false
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
