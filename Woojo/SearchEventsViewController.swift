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

class SearchEventsViewController: UIViewController, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var resultsTableView: UITableView!
    @IBOutlet var emptyView: UILabel!
    
    var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultsTableView.tableHeaderView = searchBar
        resultsTableView.register(UINib(nibName: "SearchEventsResultsTableViewCell", bundle: nil), forCellReuseIdentifier: "searchEventCell")
        resultsTableView.rowHeight = 100
        
        setupDataSource()
        
        self.resultsTableView.emptyDataSetDelegate = self
        self.resultsTableView.emptyDataSetSource = self
    }
    
    func setupDataSource() {
        Woojo.User.current.value?.events.asObservable().subscribe(onNext: { _ in
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
                    return Event.search(query: query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")
                        .retry(3)
                        //.retryOnBecomesReachable([], reachabilityService: Dependencies.sharedDependencies.reachabilityService)
                        .startWith([]) // clears results on new search term
                        .asDriver(onErrorJustReturn: [])
                }
            }
        
        results
            .drive(resultsTableView.rx.items(cellIdentifier: "searchEventCell", cellType: SearchEventsResultsTableViewCell.self)) { (_, event, cell) in
                cell.event = event
                if let isUserEvent = Woojo.User.current.value?.events.value.contains(where: { $0.id == cell.event?.id }) {
                    cell.accessoryType = isUserEvent ? .checkmark : .none
                }
            }
            .addDisposableTo(disposeBag)
        
        /*results
            .map { $0.count != 0 }
            .drive(self.emptyView.rx.isHidden)
            .addDisposableTo(disposeBag)*/
        
        /*results
            .asObservable()
            .map { $0.count != 0 }
            .subscribe(onNext: { self.resultsTableView.isScrollEnabled = $0 })
            .addDisposableTo(disposeBag)*/
        
        resultsTableView.rx.itemSelected
            .subscribe(onNext: { indexPath in
                let cell = self.resultsTableView.cellForRow(at: indexPath) as! SearchEventsResultsTableViewCell
                if let event = cell.event, let isUserEvent = Woojo.User.current.value?.events.value.contains(where: { $0.id == event.id }) {
                    let completion = { (error: Error?) -> Void in self.resultsTableView.reloadData() }
                    if isUserEvent {
                        Woojo.User.current.value?.remove(event: event, completion: completion)
                        cell.accessoryType = .none
                    } else {
                        Woojo.User.current.value?.add(event: event, completion: completion)
                        cell.accessoryType = .checkmark
                    }
                }
            }).addDisposableTo(disposeBag)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "reuseSearchheader")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Search Events", attributes: Constants.App.Appearance.EmptyDatasets.titleStringAttributes)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Find all events matching your query", attributes: Constants.App.Appearance.EmptyDatasets.descriptionStringAttributes)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return #imageLiteral(resourceName: "search_events")
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
    
    /*func backgroundColor(forEmptyDataSet scrollView: UIScrollView!) -> UIColor! {
        return UIColor(colorLiteralRed: 240/255, green: 240/255, blue: 240/255, alpha: 1.0)
    }*/

}
