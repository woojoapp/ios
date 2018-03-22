//
//  AlbumsTableViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 13/12/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import RxSwift
import DZNEmptyDataSet

class AlbumsTableViewController: UITableViewController {
    
    var photoIndex = 0
    var albums: [Album] = []
    var profileViewController: PhotoSource?
    
    let disposeBag = DisposeBag()
    var reachabilityObserver: AnyObject?
    
    @IBAction func dismiss(sender: Any?) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 100
        tableView.register(UINib(nibName: "AlbumsTableViewCell", bundle: nil), forCellReuseIdentifier: "albumCell")
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(loadFacebookAlbums), for: UIControlEvents.valueChanged)
        
        tableView.emptyDataSetDelegate = self
        tableView.emptyDataSetSource = self
        
        User.current.asObservable().subscribe(onNext: { _ in
            self.loadFacebookAlbums()
        }).disposed(by: disposeBag)
    }
    
    @objc func loadFacebookAlbums() {
        User.current.value?.getAlbumsFromFacebook { albums in
            self.albums = albums
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()
        }
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

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        //if albums.count > 0 {
            return 1
        /*} else {
            let messageLabel = UILabel(frame: CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
            messageLabel.text = "No albums found\nPull to refresh"
            messageLabel.textColor = UIColor.init(hexString: "AFAFAF")
            messageLabel.font = UIFont(name: messageLabel.font.fontName, size: 14)
            messageLabel.numberOfLines = 0
            messageLabel.textAlignment = .center
            messageLabel.sizeToFit()
            
            self.tableView.backgroundView = messageLabel
            
            return 0
        }*/
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.albums.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "albumCell", for: indexPath) as! AlbumsTableViewCell
        cell.album = albums[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let photoCollectionViewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PhotoCollectionViewController") as! PhotoCollectionViewController
        photoCollectionViewController.album = albums[indexPath.row]
        photoCollectionViewController.photoIndex = self.photoIndex
        photoCollectionViewController.profileViewController = self.profileViewController
        self.navigationController?.pushViewController(photoCollectionViewController, animated: true)
    }

}

// MARK: - DZNEmptyDataSetSource

extension AlbumsTableViewController: DZNEmptyDataSetSource {
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: NSLocalizedString("Facebook Albums", comment: ""), attributes: Constants.App.Appearance.EmptyDatasets.titleStringAttributes)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: NSLocalizedString("No albums found\n\nPull to refresh", comment: ""), attributes: Constants.App.Appearance.EmptyDatasets.descriptionStringAttributes)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return #imageLiteral(resourceName: "albums")
    }
    
}
// MARK: - DZNEmptyDataSetDelegate

extension AlbumsTableViewController: DZNEmptyDataSetDelegate {
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
    
}

extension AlbumsTableViewController: ReachabilityAware {
    
    func setReachabilityState(reachable: Bool) {
        if reachable {
            loadFacebookAlbums()
        } else {
            tableView.refreshControl?.endRefreshing()
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
