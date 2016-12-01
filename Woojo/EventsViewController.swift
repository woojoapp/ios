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

class EventsViewController: TabViewController, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = 100
        tableView.register(UINib(nibName: "EventsTableViewCell", bundle: nil), forCellReuseIdentifier: "eventCell")
        tableView.rx.setDelegate(self).addDisposableTo(disposeBag)
        
        setupDataSource()
    }
    
    override func setupDataSource() {
        super.setupDataSource()
        Woojo.User.current.asObservable()
            .flatMap { user -> Observable<[Event]> in
                if let currentUser = user {
                    return currentUser.events.asObservable()
                } else {
                    return Variable([]).asObservable()
                }
            }
            .bindTo(self.tableView.rx.items(cellIdentifier: "eventCell", cellType: EventsTableViewCell.self)) { row, event, cell in
                cell.event = event
            }.addDisposableTo(disposeBag)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete", handler: { action, indexPath in
            if let cell = self.tableView.cellForRow(at: indexPath) as? EventsTableViewCell, let event = cell.event {
                Woojo.User.current.value?.remove(event: event, completion: nil)
            }
        })
        return [deleteAction]
    }

}
