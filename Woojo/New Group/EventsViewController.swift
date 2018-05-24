//
//  EventsTableViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 03/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import RxSwift
import DZNEmptyDataSet
import PKHUD
import FacebookCore

class EventsViewController: UIViewController {
    
    @IBOutlet weak var tipView: UIView!
    @IBOutlet weak var dismissTipButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var facebookIntegrationView: UIView!
    @IBOutlet weak var facebookIntegrationActiveArea: UIView!
    @IBOutlet weak var facebookIntegrationImageView: UIImageView!
    @IBOutlet weak var facebookIntegrationButton: UIButton!
    @IBOutlet weak var facebookLaterButton: UIButton!
    
    @IBOutlet weak var eventbriteIntegrationView: UIView!
    @IBOutlet weak var eventbriteIntegrationActiveArea: UIView!
    @IBOutlet weak var eventbriteIntegrationImageView: UIImageView!
    @IBOutlet weak var eventbriteIntegrationButton: UIButton!
    @IBOutlet weak var eventbriteLaterButton: UIButton!
    
    private let viewModel = EventsViewModel()
    private var scrolled = false
    private var userEvents: [String: [User.Event]] = [:]
    private var months: [String] = []
    
    internal var disposeBag = DisposeBag()
    internal var reachabilityObserver: AnyObject?
    
    private static let HIDE_EVENTS_TIP = "HIDE_EVENTS_TIP"
    private static let INTEGRATE_EVENTBRITE_LATER = "INTEGRATE_EVENTBRITE_LATER"
    private static let INTEGRATE_FACEBOOK_LATER = "INTEGRATE_FACEBOOK_LATER"
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.dateFormat = Constants.Event.dateFormat
        return formatter
    }()
    
    private static let humanDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.dateFormat = Constants.Event.humanDateFormat
        return formatter
    }()
    
    private static let sectionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.dateFormat = "yyyyMM"
        return formatter
    }()
    
    private static let sectionHumanDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = 100
        tableView.register(R.nib.eventTableViewCell)
        
        tableView.dataSource = self
        
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(refreshEvents), for: UIControlEvents.valueChanged)
        
        bindViewModel()
        
        tableView.tableFooterView = UIView()
        
        let imageView = UIImageView(image: #imageLiteral(resourceName: "close"))
        imageView.frame = CGRect(x: dismissTipButton.frame.width/2.0, y: dismissTipButton.frame.height/2.0, width: 10, height: 10)
        dismissTipButton.addSubview(imageView)
        
        setTip()
        //disableFacebookIntegration()
    }
    
    @objc private func refreshEvents() {
        viewModel.syncEventbriteEvents().always {
            self.tableView.refreshControl?.endRefreshing()
        }
    }
    
    @IBAction func tapped(tapGestureRecognizer: UITapGestureRecognizer) {
        if tapGestureRecognizer.state == .ended {
            if let tableView = tapGestureRecognizer.view as? UITableView,
                let indexPath = tableView.indexPathForRow(at: tapGestureRecognizer.location(in: tableView)),
                let cell = tableView.cellForRow(at: indexPath) as? EventTableViewCell {
                let point = tapGestureRecognizer.location(in: cell)
                if let userEvent = getUserEvent(indexPath: indexPath), let eventId = userEvent.event.id {
                    if cell.activateArea.frame.contains(point) {
                        if userEvent.active {
                            viewModel.deactivateEvent(eventId: eventId).catch { _ in }
                        } else {
                            viewModel.activateEvent(eventId: eventId).catch { _ in }
                        }
                    } else {
                        showDetails(event: userEvent.event)
                    }
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        showSettingsButton()
        let settingsButton = self.navigationItem.rightBarButtonItem?.customView as? UIButton
        settingsButton?.addTarget(self, action: #selector(showSettings(sender:)), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        startMonitoringReachability()
        checkReachability()
        UserRepository.shared.setLastSeen(date: Date()).catch { _ in }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UserNotificationRepository.shared.deleteAll(type: "events").catch { _ in }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        stopMonitoringReachability()
    }
    
    func bindViewModel() {
        viewModel.events
            .drive(onNext: { userEvents in
                print("NNEW EVVENTS", userEvents)
                self.userEvents = userEvents.group(by: { EventsViewController.sectionDateFormatter.string(from: $0.event.start!) }).mapValues{ $0.sorted(by: { $0.event.start! > $1.event.start! }) }
                self.months = Array(self.userEvents.keys).sorted().reversed()
                self.tableView.reloadData()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    self.scrollToNow()
                })
                Analytics.setUserProperties(properties: ["event_count": String(userEvents.count)])
            }).disposed(by: disposeBag)

        viewModel.isEventbriteIntegrated
            .map { isIntegrated -> Bool in
                let integrateEventbriteLater = UserDefaults.standard.bool(forKey: EventsViewController.INTEGRATE_EVENTBRITE_LATER)
                return isIntegrated || integrateEventbriteLater
            }
            .drive(eventbriteIntegrationView.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.isFacebookIntegrated
            .map{
                let integrateFacebookLater = UserDefaults.standard.bool(forKey: EventsViewController.INTEGRATE_FACEBOOK_LATER)
                return $0 || integrateFacebookLater
            }
            .drive(facebookIntegrationView.rx.isHidden)
            .disposed(by: disposeBag)
    }
    
    /*private func getMonthString(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.dateFormat = "yyyyMM"
        return formatter.string(from: date)
    }*/
    
    private func disableFacebookIntegration() {
        facebookIntegrationActiveArea.alpha = 0.3
        facebookIntegrationImageView.image = R.image.facebookIcon()?.desaturate()
    }
    
    @IBAction func integrateEventbrite() {
        let navigationController = UINavigationController()
        navigationController.pushViewController(EventbriteLoginViewController(), animated: false)
        self.present(navigationController, animated: true, completion: nil)
    }
    
    @IBAction func integrateFacebook() {
        
    }
    
    @IBAction func displayFacebookAlert() {
        let alert = UIAlertController(title: NSLocalizedString("Currently unavailable", comment: ""), message: NSLocalizedString("Due to temporary changes in Facebook\'s privacy policy, your events are inaccessible at this time.\n\nThis feature will be re-activated when access is restored.", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func integrateEventbriteLater() {
        UserDefaults.standard.set(true, forKey: EventsViewController.INTEGRATE_EVENTBRITE_LATER)
        eventbriteIntegrationView.isHidden = true
    }
    
    @IBAction func integrateFacebookLater() {
        UserDefaults.standard.set(true, forKey: EventsViewController.INTEGRATE_FACEBOOK_LATER)
        facebookIntegrationView.isHidden = true
    }
    
    private func scrollToNow() {
        if !self.scrolled {
            if let month = self.months.reversed().first(where: {
                if let current = Int($0), let reference = Int(EventsViewController.sectionDateFormatter.string(from: Date())) {
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
    
    private func getUserEvent(indexPath: IndexPath) -> User.Event? {
        return userEvents[months[indexPath.section]]?[indexPath.row]
    }
    
    private func showDetails(event: Event) {
        if let eventDetailsViewController = R.storyboard.main.eventDetailsViewController() {
            eventDetailsViewController.event = event
            navigationController?.pushViewController(eventDetailsViewController, animated: true)
        }
    }
    
    @IBAction func dismissTip() {
        UserDefaults.standard.set(true, forKey: EventsViewController.HIDE_EVENTS_TIP)
        tipView.isHidden = true
    }
    
    private func setTip() {
        tipView.isHidden = UserDefaults.standard.bool(forKey: EventsViewController.HIDE_EVENTS_TIP)
    }
}

extension EventsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return months.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userEvents[months[section]]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.eventCell, for: indexPath)!
        cell.event = self.userEvents[months[indexPath.section]]?[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let monthAsDate = EventsViewController.sectionDateFormatter.date(from: months[section]) {
            return EventsViewController.sectionHumanDateFormatter.string(from: monthAsDate).capitalized
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if let reachable = isReachable(), reachable {
            return true
        } else { return false }
    }
}

extension EventsViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return tableView.indexPathForRow(at: gestureRecognizer.location(in: tableView)) != nil
    }
}

extension EventsViewController: ShowsSettingsButton {
    @objc func showSettings(sender : Any?) {
        if let settingsNavigationController = R.storyboard.main.settingsNavigationController() {
            self.present(settingsNavigationController, animated: true, completion: nil)
        }
    }
}

extension EventsViewController: DZNEmptyDataSetSource {
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: NSLocalizedString("No Events Yet", comment: ""), attributes: Constants.App.Appearance.EmptyDatasets.titleStringAttributes)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: NSLocalizedString("Click the + button to add events", comment: ""), attributes: Constants.App.Appearance.EmptyDatasets.descriptionStringAttributes)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return #imageLiteral(resourceName: "events")
    }
}

extension EventsViewController: DZNEmptyDataSetDelegate {
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
}

extension EventsViewController: ReachabilityAware {
    func setReachabilityState(reachable: Bool) {
        if reachable {
            
        } else {
            tableView.setEditing(false, animated: true)
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
