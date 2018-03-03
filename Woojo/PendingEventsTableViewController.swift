//
//  PendingEventsTableViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 16/11/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import UIKit
import RxSwift
import DZNEmptyDataSet
import PKHUD

class PendingEventsTableViewController: UITableViewController {
    
    var events: [Event] = []
    let disposeBag = DisposeBag()
    var reachabilityObserver: AnyObject?
    @IBOutlet weak var tipView: UIView!
    @IBOutlet weak var dismissTipButton: UIButton!
    let tipId = "newEvents"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = 100
        tableView.register(UINib(nibName: "MyEventsTableViewCell", bundle: nil), forCellReuseIdentifier: "fbEventCell")
        
        //tableView.refreshControl = UIRefreshControl()
        //tableView.refreshControl?.addTarget(self, action: #selector(loadFacebookEvents), for: UIControlEvents.valueChanged)
        
        tableView.emptyDataSetDelegate = self
        tableView.emptyDataSetSource = self
        
        User.current.asObservable().subscribe(onNext: { (user) in
            if let tips = user?.tips, tips[self.tipId] != nil {
                self.tableView.tableHeaderView = nil
            }
        }).disposed(by: disposeBag)
        
        User.current.value?.pendingEvents.asObservable().subscribe(onNext: { pendingEvents in
            self.events = pendingEvents
            self.tableView.reloadData()
        }).disposed(by: disposeBag)
        
        let imageView = UIImageView(image: #imageLiteral(resourceName: "close"))
        imageView.frame = CGRect(x: dismissTipButton.frame.width/2.0, y: dismissTipButton.frame.height/2.0, width: 10, height: 10)
        dismissTipButton.addSubview(imageView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        startMonitoringReachability()
        checkReachability()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopMonitoringReachability()
    }
    
    @IBAction func dismissTip() {
        Woojo.User.current.value?.dismissTip(tipId: self.tipId)
        UIView.beginAnimations("foldHeader", context: nil)
        self.tableView.tableHeaderView = nil
        UIView.commitAnimations()
    }
    
    @IBAction func dismiss() {
        self.dismiss(animated: true)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if events.count > 0 {
            return 1
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fbEventCell", for: indexPath) as! MyEventsTableViewCell
        cell.event = self.events[indexPath.row]
        if let isUserEvent = User.current.value?.events.value.contains(where: { $0.id == cell.event?.id }) {
            cell.checkView.isHidden = !isUserEvent
        }
        return cell
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let reachable = isReachable(), reachable {
            let event = self.events[indexPath.row]
            if let isUserEvent = User.current.value?.events.value.contains(where: { $0.id == event.id }) {
                if let cell = tableView.cellForRow(at: indexPath) as? MyEventsTableViewCell {
                    if isUserEvent {
                        HUD.show(.labeledProgress(title: NSLocalizedString("Remove Event", comment: ""), subtitle: NSLocalizedString("Removing event...", comment: "")))
                        User.current.value?.remove(event: event, completion: { (error: Error?) -> Void in
                            cell.checkView.isHidden = true
                            tableView.reloadRows(at: [indexPath], with: .automatic)
                            HUD.show(.labeledSuccess(title: NSLocalizedString("Remove Event", comment: ""), subtitle: NSLocalizedString("Event removed!", comment: "")))
                            HUD.hide(afterDelay: 1.0)
                            let analyticsEventParameters = [Constants.Analytics.Events.EventRemoved.Parameters.id: event.id,
                                                            Constants.Analytics.Events.EventRemoved.Parameters.screen: String(describing: type(of: self))]
                            Analytics.Log(event: Constants.Analytics.Events.EventRemoved.name, with: analyticsEventParameters)
                        })
                    } else {
                        HUD.show(.labeledProgress(title: NSLocalizedString("Add Event", comment: ""), subtitle: NSLocalizedString("Adding event...", comment: "")))
                        User.current.value?.add(event: event, completion: { (error: Error?) -> Void in
                            cell.checkView.isHidden = false
                            tableView.reloadRows(at: [indexPath], with: .automatic)
                            HUD.show(.labeledSuccess(title: NSLocalizedString("Add Event", comment: ""), subtitle: NSLocalizedString("Event added!", comment: "")))
                            HUD.hide(afterDelay: 1.0)
                            let analyticsEventParameters = [Constants.Analytics.Events.EventAdded.Parameters.id: event.id,
                                                            Constants.Analytics.Events.EventAdded.Parameters.screen: String(describing: type(of: self))]
                            Analytics.Log(event: Constants.Analytics.Events.EventAdded.name, with: analyticsEventParameters)
                        })
                    }
                }
            }
        }
    }
    
}

// MARK: - DZNEmptyDataSetSource

extension PendingEventsTableViewController: DZNEmptyDataSetSource {
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: NSLocalizedString("New Events", comment: ""), attributes: Constants.App.Appearance.EmptyDatasets.titleStringAttributes)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: NSLocalizedString("You don't have any new event on Facebook.", comment: ""), attributes: Constants.App.Appearance.EmptyDatasets.descriptionStringAttributes)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return #imageLiteral(resourceName: "events")
    }
    
}
// MARK: - DZNEmptyDataSetDelegate

extension PendingEventsTableViewController: DZNEmptyDataSetDelegate {
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
    
}

// MARK: - ReachabilityAware

extension PendingEventsTableViewController: ReachabilityAware {
    
    func setReachabilityState(reachable: Bool) {
        //tableView.refreshControl?.endRefreshing()
        if reachable {
            //loadFacebookEvents()
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
