//
//  SearchEventsViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 28/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import DZNEmptyDataSet
import PKHUD

class SearchEventsViewController: UIViewController {

    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var resultsTableView: UITableView!
    //@IBOutlet var emptyView: UILabel!
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    
    var disposeBag = DisposeBag()
    var reachabilityObserver: AnyObject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultsTableView.register(UINib(nibName: "SearchEventsResultsTableViewCell", bundle: nil), forCellReuseIdentifier: "searchEventCell")
        resultsTableView.rowHeight = 100
        
        setupDataSource()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        resultsTableView.emptyDataSetDelegate = self
        resultsTableView.emptyDataSetSource = self
        
        resultsTableView.layoutSubviews()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
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

    func setupDataSource() {
        User.current.value?.events.asObservable().subscribe(onNext: { _ in
            self.resultsTableView.reloadData()
        }).addDisposableTo(disposeBag)
        
        let results = searchBar.rx.text.orEmpty
            .asDriver()
            .throttle(0.3)
            .distinctUntilChanged()
            .flatMapLatest { query -> SharedSequence<DriverSharingStrategy, Array<Event>> in
                if query.isEmpty {
                    return Observable.just([])
                        .asDriver(onErrorJustReturn: [])
                } else {
                    return Event.search(query: query)
                        .retry(3)
                        .startWith([])
                        .asDriver(onErrorJustReturn: [])
                }
            }
        
        results
            .drive(resultsTableView.rx.items(cellIdentifier: "searchEventCell", cellType: SearchEventsResultsTableViewCell.self)) { (_, event, cell) in
                cell.event = event
                if let isUserEvent = User.current.value?.events.value.contains(where: { $0.id == cell.event?.id }) {
                    cell.checkView.isHidden = !isUserEvent
                }
            }
            .addDisposableTo(disposeBag)
        
        resultsTableView.rx.itemSelected
            .subscribe(onNext: { indexPath in
                if let reachable = self.isReachable(),
                    reachable,
                    let cell = self.resultsTableView.cellForRow(at: indexPath) as? SearchEventsResultsTableViewCell,
                    let event = cell.event,
                    let isUserEvent = User.current.value?.events.value.contains(where: { $0.id == event.id }) {
                    if isUserEvent {
                        self.remove(event: event) { error in
                            if error == nil {
                                cell.checkView.isHidden = true
                            }
                        }
                    } else {
                        self.add(event: event) { error in
                            if error == nil {
                                cell.checkView.isHidden = false                                
                            }
                        }
                    }
                }
            }).addDisposableTo(disposeBag)
    }
    
    func remove(event: Event, completion: ((Error?) -> Void)? = nil) {
        HUD.show(.labeledProgress(title: NSLocalizedString("Remove Event", comment: ""), subtitle: NSLocalizedString("Removing event...", comment: "")))
        User.current.value?.remove(event: event, completion: { (error: Error?) -> Void in
            completion?(error)
            self.resultsTableView.reloadData()
            HUD.show(.labeledSuccess(title: NSLocalizedString("Remove Event", comment: ""), subtitle: NSLocalizedString("Event removed!", comment: "")))
            HUD.hide(afterDelay: 1.0)
            let analyticsEventParameters = ["event_id": event.id,
                                            "origin": "add_events"]
            Analytics.Log(event: "Events_event_removed", with: analyticsEventParameters)
        })
    }
    
    func add(event: Event, completion: ((Error?) -> Void)? = nil) {
        HUD.show(.labeledProgress(title: NSLocalizedString("Add Event", comment: ""), subtitle: NSLocalizedString("Adding event...", comment: "")))
        User.current.value?.add(event: event, completion: { (error: Error?) -> Void in
            completion?(error)
            self.resultsTableView.reloadData()
            HUD.show(.labeledSuccess(title: NSLocalizedString("Add Event", comment: ""), subtitle: NSLocalizedString("Event added!", comment: "")))
            HUD.hide(afterDelay: 1.0)
            Analytics.addToAmplitudeUserProperty(name: "facebook_event_added_count", value: 1)
            let analyticsEventParameters = ["event_id": event.id,
                                            "source": "search"]
            Analytics.Log(event: "Events_event_added", with: analyticsEventParameters)
        })
    }
    
    @objc func keyboardWillShow(_ notification: NSNotification) {
        if let keyboardFrameEnd = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect, let animationDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval, let navigationController = navigationController {
            bottomConstraint.constant = self.view.frame.size.height - keyboardFrameEnd.origin.y + navigationController.navigationBar.frame.size.height + UIApplication.shared.statusBarFrame.size.height + searchBar.frame.size.height
            UIView.animate(withDuration: animationDuration, animations: {
                self.view.layoutIfNeeded()
            }, completion: { finished in
                
            })
        }
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification) {
        if let animationDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval {
            bottomConstraint.constant = 0
            UIView.animate(withDuration: animationDuration, animations: {
                self.view.layoutIfNeeded()
            }, completion: { finished in
                
            })
        }
    }

}

// MARK: - UITableViewDelegate

/*extension SearchEventsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "reuseSearchheader")
    }
    
}*/

// MARK: - DZNEmptyDataSetSource

extension SearchEventsViewController: DZNEmptyDataSetSource {
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: NSLocalizedString("Search Events", comment: ""), attributes: Constants.App.Appearance.EmptyDatasets.titleStringAttributes)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: NSLocalizedString("Find events by name", comment: ""), attributes: Constants.App.Appearance.EmptyDatasets.descriptionStringAttributes)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return #imageLiteral(resourceName: "search_events")
    }
    
}

// MARK: - DZNEmptyDataSetDelegate

extension SearchEventsViewController: DZNEmptyDataSetDelegate {
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
    
}

// MARK: - ReachabilityAware

extension SearchEventsViewController: ReachabilityAware {
    
    func setReachabilityState(reachable: Bool) {
        searchBar.isUserInteractionEnabled = reachable
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
