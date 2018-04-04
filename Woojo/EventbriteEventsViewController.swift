//
//  MyEventsTableViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 08/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import DZNEmptyDataSet
import PKHUD

class EventbriteEventsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var events: [String: [Event]] = [:]
    var months: [String] = []
    let disposeBag = DisposeBag()
    var reachabilityObserver: AnyObject?
    @IBOutlet weak var tipView: UIView!
    @IBOutlet weak var dismissTipButton: UIButton!
    @IBOutlet weak var loginView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loginButton: UIButton!
    let tipId = "eventbriteEvents"
    private var eventbriteAccessTokenObserver: UInt?
    private var scrolled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.rowHeight = 100
        tableView.register(UINib(nibName: "MyEventsTableViewCell", bundle: nil), forCellReuseIdentifier: "fbEventCell")
        
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(loadEventbriteEvents), for: UIControlEvents.valueChanged)
        
        tableView.emptyDataSetDelegate = self
        tableView.emptyDataSetSource = self
        
        loadEventbriteEvents()
        
        User.current.asObservable().subscribe(onNext: { (user) in
            if let tips = user?.tips, tips[self.tipId] != nil {
                self.tableView.tableHeaderView = nil
            }
        }).disposed(by: disposeBag)
        
        User.current.value?.events.asObservable().subscribe(onNext: { _ in
            self.tableView.reloadData()
        }).disposed(by: disposeBag)
        
        let imageView = UIImageView(image: #imageLiteral(resourceName: "close"))
        imageView.frame = CGRect(x: dismissTipButton.frame.width/2.0, y: dismissTipButton.frame.height/2.0, width: 10, height: 10)
        dismissTipButton.addSubview(imageView)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        startObservingEventbriteAccessToken()
        if events.count == 0 {
            loadEventbriteEvents()
        }
        startMonitoringReachability()
        checkReachability()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopMonitoringReachability()
    }
    
    func startObservingEventbriteAccessToken() {
        eventbriteAccessTokenObserver = User.current.value?.getEventbriteAccessTokenReference()
            .observe(.value, with: { (snapshot) in
                self.setupUI(eventbriteIntegrated: snapshot.exists(), accessToken: snapshot.value as? String)
            })
    }
    
    func stopObservingEventbriteAccessToken() {
        if eventbriteAccessTokenObserver != nil {
            User.current.value?.getEventbriteAccessTokenReference()
                .removeObserver(withHandle: eventbriteAccessTokenObserver!)
        }
    }
    
    func setupUI(eventbriteIntegrated: Bool, accessToken: String?) {
        if eventbriteIntegrated {
            loginView.isHidden = true
            tableView.isHidden = false
        } else {
            loginView.isHidden = false
            tableView.isHidden = true
        }
    }
    
    @objc func loadEventbriteEvents() {
        User.current.value?.getEventsFromEventbrite { events in
            self.events = events.group(by: { $0.monthString })
            self.months = Array(self.events.keys).sorted().reversed()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.scrollToNow()
            })
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()
            self.tableView.backgroundView?.isHidden = self.events.count > 0
        }
    }
    
    @IBAction func dismissTip() {
        Woojo.User.current.value?.dismissTip(tipId: self.tipId)
        UIView.beginAnimations("foldHeader", context: nil)
        self.tableView.tableHeaderView = nil
        UIView.commitAnimations()
    }
    
    func scrollToNow() {
        if !self.scrolled {
            if let month = self.months.reversed().first(where: {
                if let current = Int($0), let reference = Int(Event.sectionDateFormatter.string(from: Date())) {
                    return current >= reference
                }
                return false
            }), let index = self.months.index(of: month) {
                let indexPath = IndexPath(row: 0, section: index)
                self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                self.scrolled = true
            }
        }
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if events.count > 0 {
            return months.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let monthAsDate = Event.sectionDateFormatter.date(from: months[section]) {
            return Event.sectionHumanDateFormatter.string(from: monthAsDate).capitalized
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events[months[section]]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fbEventCell", for: indexPath) as! MyEventsTableViewCell
        cell.event = self.events[months[indexPath.section]]?[indexPath.row]
        if let isUserEvent = User.current.value?.events.value.contains(where: { $0.id == cell.event?.id }) {
            if isUserEvent {
                cell.checkView.image = #imageLiteral(resourceName: "check")
            } else {
                cell.checkView.image = #imageLiteral(resourceName: "plus")
            }
        }
        return cell
    }
    
    // MARK: - Table view delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let reachable = isReachable(), reachable {
            if let event = self.events[months[indexPath.section]]?[indexPath.row],
                let isUserEvent = User.current.value?.events.value.contains(where: { $0.id == event.id }) {
                if let cell = tableView.cellForRow(at: indexPath) as? MyEventsTableViewCell {
                    if isUserEvent {
                        HUD.show(.labeledProgress(title: NSLocalizedString("Remove Event", comment: ""), subtitle: NSLocalizedString("Removing event...", comment: "")))
                        User.current.value?.remove(event: event, completion: { (error: Error?) -> Void in
                            cell.checkView.image = #imageLiteral(resourceName: "plus")
                            tableView.reloadRows(at: [indexPath], with: .none)
                            HUD.show(.labeledSuccess(title: NSLocalizedString("Remove Event", comment: ""), subtitle: NSLocalizedString("Event removed!", comment: "")))
                            HUD.hide(afterDelay: 1.0)
                            let analyticsEventParameters = ["event_id": event.id,
                                                            "origin": "add_events"]
                            Analytics.Log(event: "Events_event_removed", with: analyticsEventParameters)
                        })
                    } else {
                        HUD.show(.labeledProgress(title: NSLocalizedString("Add Event", comment: ""), subtitle: NSLocalizedString("Adding event...", comment: "")))
                        User.current.value?.add(event: event, completion: { (error: Error?) -> Void in
                            cell.checkView.image = #imageLiteral(resourceName: "check")
                            tableView.reloadRows(at: [indexPath], with: .none)
                            HUD.show(.labeledSuccess(title: NSLocalizedString("Add Event", comment: ""), subtitle: NSLocalizedString("Event added!", comment: "")))
                            HUD.hide(afterDelay: 1.0)
                            Analytics.addToAmplitudeUserProperty(name: "eventbrite_event_added_count", value: 1)
                            let analyticsEventParameters = ["event_id": event.id,
                                                            "source": "eventbrite"]
                            Analytics.Log(event: "Events_event_added", with: analyticsEventParameters)
                        })
                    }
                }
            }
        }
    }
    
}

// MARK: - DZNEmptyDataSetSource

extension EventbriteEventsViewController: DZNEmptyDataSetSource {
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: NSLocalizedString("Eventbrite Events", comment: ""), attributes: Constants.App.Appearance.EmptyDatasets.titleStringAttributes)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: NSLocalizedString("Pull to refresh", comment: ""), attributes: Constants.App.Appearance.EmptyDatasets.descriptionStringAttributes)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return #imageLiteral(resourceName: "eventbrite_logo_light_gray_128")
    }
    
}
// MARK: - DZNEmptyDataSetDelegate

extension EventbriteEventsViewController: DZNEmptyDataSetDelegate {
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
    
}

// MARK: - ReachabilityAware

extension EventbriteEventsViewController: ReachabilityAware {
    
    func setReachabilityState(reachable: Bool) {
        //tableView.refreshControl?.endRefreshing()
        if reachable {
            loadEventbriteEvents()
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


