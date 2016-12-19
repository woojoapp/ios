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

class MyEventsTableViewController: UITableViewController {
    
    var events: [Event]?
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 100
        tableView.register(UINib(nibName: "MyEventsTableViewCell", bundle: nil), forCellReuseIdentifier: "fbEventCell")
        
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(loadFacebookEvents), for: UIControlEvents.valueChanged)
        
        loadFacebookEvents()
        
        Woojo.User.current.value?.events.asObservable().subscribe(onNext: { _ in
            self.tableView.reloadData()
        }).addDisposableTo(disposeBag)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func loadFacebookEvents() {
        Woojo.User.current.value?.getEventsFromFacebook { events in
            self.events = events
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()
            //self.tableView.isScrollEnabled = self.events?.count ?? 0 > 0
            self.tableView.backgroundView?.isHidden = self.events?.count ?? 0 > 0
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        if events != nil && events?.count ?? 0 > 0 {
            self.tableView.separatorStyle = .singleLine
            return 1
        } else {
            let messageLabel = UILabel(frame: CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
            messageLabel.text = "No events found\nPull to refresh"
            messageLabel.textColor = UIColor.init(hexString: "AFAFAF")
            messageLabel.font = UIFont(name: messageLabel.font.fontName, size: 14)
            messageLabel.numberOfLines = 0
            messageLabel.textAlignment = .center
            messageLabel.sizeToFit()
            
            self.tableView.backgroundView = messageLabel
            self.tableView.separatorStyle = .none
            
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let events = events {
            return events.count
        } else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fbEventCell", for: indexPath) as! MyEventsTableViewCell
        cell.event = self.events?[indexPath.row]
        if let isUserEvent = Woojo.User.current.value?.events.value.contains(where: { $0.id == cell.event?.id }) {
            cell.accessoryType = isUserEvent ? .checkmark : .none
        }
        return cell
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Tapped")
        if let event = self.events?[indexPath.row], let isUserEvent = Woojo.User.current.value?.events.value.contains(where: { $0.id == event.id }) {
            let completion = { (error: Error?) -> Void in tableView.reloadRows(at: [indexPath], with: .none) }
            if isUserEvent {
                Woojo.User.current.value?.remove(event: event, completion: completion)
                tableView.cellForRow(at: indexPath)?.accessoryType = .none
            } else {
                Woojo.User.current.value?.add(event: event, completion: completion)
                tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
            }
        }
    }
    
}
