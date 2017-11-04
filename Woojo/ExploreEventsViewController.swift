//
//  ExploreEventsViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 06/12/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import RxSwift
import DZNEmptyDataSet
import PKHUD

class ExploreEventsViewController: UITableViewController {
    
    var events: [Event] = []
    var reachabilityObserver: AnyObject?
    var disposeBag = DisposeBag()
    @IBOutlet weak var tipView: UIView!
    @IBOutlet weak var dismissTipButton: UIButton!
    let tipId = "exploreEvents"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
        
        //if Application.remoteConfig.configValue(forKey: Constants.App.RemoteConfig.Keys.recommendedEventsEnabled).boolValue {
            setupDataSource()
            tableView.dataSource = self
            tableView.delegate = self
        //}
        
        tableView.rowHeight = 100
        tableView.register(UINib(nibName: "ExploreEventsTableViewCell", bundle: nil), forCellReuseIdentifier: "exploreEventCell")
        
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(recommendEvents), for: UIControlEvents.valueChanged)
        
        let imageView = UIImageView(image: #imageLiteral(resourceName: "close"))
        imageView.frame = CGRect(x: dismissTipButton.frame.width/2.0, y: dismissTipButton.frame.height/2.0, width: 10, height: 10)
        dismissTipButton.addSubview(imageView)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startMonitoringReachability()
        checkReachability()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopMonitoringReachability()
    }

    
    func recommendEvents() {
        print("Recommending events")
        User.current.value?.requestRecommendedEventsUpdate(completion: {
            self.tableView.refreshControl?.endRefreshing()
        })
    }
    
    func setupDataSource() {
        User.current.asObservable()
            .flatMap { user -> Observable<[Event]> in
                if let currentUser = user {
                    if let tips = user?.tips, tips[self.tipId] != nil {
                        self.tableView.tableHeaderView = nil
                    }
                    return currentUser.recommendedEvents.asObservable()
                } else {
                    return Variable([]).asObservable()
                }
            }
            .subscribe(onNext: { events in
                self.events = events
                self.tableView.reloadData()
            }).addDisposableTo(disposeBag)
    }
    
    @IBAction
    func dismissTip() {
        Woojo.User.current.value?.dismissTip(tipId: self.tipId)
        UIView.beginAnimations("foldHeader", context: nil)
        self.tableView.tableHeaderView = nil
        UIView.commitAnimations()
    }
    
    // MARK: - Table view datasource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "exploreEventCell", for: indexPath) as! ExploreEventsTableViewCell
        cell.event = self.events[indexPath.row]
        if let isUserEvent = User.current.value?.events.value.contains(where: { $0.id == cell.event?.id }) {
            cell.checkView.isHidden = !isUserEvent
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let reachable = isReachable(), reachable {
            let event = self.events[indexPath.row]
            if let isUserEvent = User.current.value?.events.value.contains(where: { $0.id == event.id }) {
                if let cell = tableView.cellForRow(at: indexPath) as? ExploreEventsTableViewCell {
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

extension ExploreEventsViewController: DZNEmptyDataSetSource {
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Explore Events", attributes: Constants.App.Appearance.EmptyDatasets.titleStringAttributes)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "No recommended events at this time", attributes: Constants.App.Appearance.EmptyDatasets.descriptionStringAttributes)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return #imageLiteral(resourceName: "explore_events")
    }
}

extension ExploreEventsViewController: DZNEmptyDataSetDelegate {
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
}

extension ExploreEventsViewController: ReachabilityAware {
    func setReachabilityState(reachable: Bool) {
        if reachable {
            
        } else {
            
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
