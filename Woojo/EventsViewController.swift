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

/*class CurrentUserViewModel {
    
    let disposeBag = DisposeBag()
    var profileImage: Variable<UIImage>
    
    init(currentUser: CurrentUser) {
        profileImage = Variable<UIImage>(currentUser)
    }
    
}*/

class EventsViewController: UIViewController, UITableViewDelegate {
    
    //var dataSource: FUITableViewDataSource!
    
    @IBOutlet weak var tableView: UITableView!
    
    var authStateDidChangeListenerHandle: FIRAuthStateDidChangeListenerHandle?
    
    let disposeBag = DisposeBag()
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = 100
        tableView.register(UINib(nibName: "EventsTableViewCell", bundle: nil), forCellReuseIdentifier: "eventCell")
        tableView.rx.setDelegate(self).addDisposableTo(disposeBag)
        
        setupDataSource()
        
        let settingsItem = UIBarButtonItem()
        let settingsButton = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        settingsButton.layer.cornerRadius = settingsButton.frame.width / 2
        settingsButton.layer.masksToBounds = true
        settingsButton.addTarget(self, action: #selector(showSettings), for: .touchUpInside)
        //settingsButton.imageView?.
        //settingsButton.imageView?.image?.rx.bi
        /*Woojo.User.current?
            .shareReplay(1)
            .map{ $0.profile.displayName }
            .subscribe(onNext: { name in
                print(name)
            })*/
        /*
 User.current?.asObservable()
            .map({ $0.profile })
            .map({ $0. })*/
        //settingsButton.imageView?.rx.image
        settingsItem.customView = settingsButton
        self.navigationItem.setRightBarButton(settingsItem, animated: true)
        
    }
    
    func showSettings(sender : Any?) {
        let settingsController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "settingsNavigation")
        self.present(settingsController, animated: true, completion: nil)
    }
    
    func setupDataSource() {
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
