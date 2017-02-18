//
//  SearchCitiesViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 16/02/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import DZNEmptyDataSet

class SearchCitiesViewController: UIViewController, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var resultsTableView: UITableView!
    
    var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //resultsTableView.tableHeaderView = searchBar
        //resultsTableView.rowHeight = 100
        
        //setupDataSource()
        
        self.resultsTableView.emptyDataSetDelegate = self
        self.resultsTableView.emptyDataSetSource = self
    }
    
    /*func setupDataSource() {
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
                    print(query)
                    /*return Event.search(query: query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")
                        .retry(3)
                        //.retryOnBecomesReachable([], reachabilityService: Dependencies.sharedDependencies.reachabilityService)
                        .startWith([]) // clears results on new search term
                        .asDriver(onErrorJustReturn: [])*/
                }
        }
        
        results
            .drive(resultsTableView.rx.items(cellIdentifier: "cityCell", cellType: UITableViewCell.self)) { (_, city, cell) in
                cell.textLabel = city
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
                let cell = self.resultsTableView.cellForRow(at: indexPath)
                /*if let event = cell.event, let isUserEvent = Woojo.User.current.value?.events.value.contains(where: { $0.id == event.id }) {
                    let completion = { (error: Error?) -> Void in self.resultsTableView.reloadData() }
                    if isUserEvent {
                        Woojo.User.current.value?.remove(event: event, completion: completion)
                        cell.accessoryType = .none
                    } else {
                        Woojo.User.current.value?.add(event: event, completion: completion)
                        cell.accessoryType = .checkmark
                    }
                }*/
            }).addDisposableTo(disposeBag)
    }*/
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "reuseSearchheader")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Find Your City", attributes: Constants.App.Appearance.EmptyDatasets.titleStringAttributes)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Search by city name", attributes: Constants.App.Appearance.EmptyDatasets.descriptionStringAttributes)
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
