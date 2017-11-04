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

class MyEventsTableViewController: UITableViewController {
    
    var events: [Event] = []
    let disposeBag = DisposeBag()
    var reachabilityObserver: AnyObject?
    @IBOutlet weak var tipView: UIView!
    @IBOutlet weak var dismissTipButton: UIButton!
    let tipId = "facebookEvents"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = 100
        tableView.register(UINib(nibName: "MyEventsTableViewCell", bundle: nil), forCellReuseIdentifier: "fbEventCell")
        
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(loadFacebookEvents), for: UIControlEvents.valueChanged)
        
        tableView.emptyDataSetDelegate = self
        tableView.emptyDataSetSource = self
        
        loadFacebookEvents()
        
        User.current.value?.events.asObservable().subscribe(onNext: { _ in
            self.tableView.reloadData()
        }).addDisposableTo(disposeBag)
        
        let imageView = UIImageView(image: #imageLiteral(resourceName: "close"))
        imageView.frame = CGRect(x: dismissTipButton.frame.width/2.0, y: dismissTipButton.frame.height/2.0, width: 10, height: 10)
        dismissTipButton.addSubview(imageView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if events.count == 0 {
            loadFacebookEvents()
        }
        startMonitoringReachability()
        checkReachability()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopMonitoringReachability()
    }

    func loadFacebookEvents() {
        User.current.value?.getEventsFromFacebook { events in
            self.events = events
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()
            self.tableView.backgroundView?.isHidden = self.events.count > 0
        }
    }
    
    @IBAction
    func dismissTip() {
        Woojo.User.current.value?.dismissTip(tipId: self.tipId)
        UIView.beginAnimations("foldHeader", context: nil)
        self.tableView.tableHeaderView = nil
        UIView.commitAnimations()
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
                print(isUserEvent)
                if let cell = tableView.cellForRow(at: indexPath) as? MyEventsTableViewCell {
                    if isUserEvent {
                        HUD.show(.labeledProgress(title: "Remove Event", subtitle: "Removing event..."))
                        User.current.value?.remove(event: event, completion: { (error: Error?) -> Void in
                            cell.checkView.isHidden = true
                            tableView.reloadRows(at: [indexPath], with: .none)
                            HUD.show(.labeledSuccess(title: "Remove Event", subtitle: "Event removed!"))
                            HUD.hide(afterDelay: 1.0)
                            let analyticsEventParameters = [Constants.Analytics.Events.EventRemoved.Parameters.name: event.name,
                                                            Constants.Analytics.Events.EventRemoved.Parameters.id: event.id,
                                                            Constants.Analytics.Events.EventRemoved.Parameters.screen: String(describing: type(of: self))]
                            Analytics.Log(event: Constants.Analytics.Events.EventRemoved.name, with: analyticsEventParameters)
                        })
                    } else {
                        HUD.show(.labeledProgress(title: "Add Event", subtitle: "Adding event..."))
                        User.current.value?.add(event: event, completion: { (error: Error?) -> Void in
                            cell.checkView.isHidden = false
                            tableView.reloadRows(at: [indexPath], with: .none)
                            HUD.show(.labeledSuccess(title: "Add Event", subtitle: "Event added!"))
                            HUD.hide(afterDelay: 1.0)
                            let analyticsEventParameters = [Constants.Analytics.Events.EventAdded.Parameters.name: event.name,
                                                            Constants.Analytics.Events.EventAdded.Parameters.id: event.id,
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

extension MyEventsTableViewController: DZNEmptyDataSetSource {
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "My Events", attributes: Constants.App.Appearance.EmptyDatasets.titleStringAttributes)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Only events from the past month or in the future are shown.\n\nPull to refresh", attributes: Constants.App.Appearance.EmptyDatasets.descriptionStringAttributes)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return #imageLiteral(resourceName: "my_events")
    }
    
}
// MARK: - DZNEmptyDataSetDelegate

extension MyEventsTableViewController: DZNEmptyDataSetDelegate {
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
    
}

// MARK: - ReachabilityAware

extension MyEventsTableViewController: ReachabilityAware {
    
    func setReachabilityState(reachable: Bool) {
        //tableView.refreshControl?.endRefreshing()
        if reachable {
            loadFacebookEvents()
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

