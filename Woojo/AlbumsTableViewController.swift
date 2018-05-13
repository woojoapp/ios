//
//  AlbumsTableViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 13/12/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import FirebaseAuth
import RxSwift
import DZNEmptyDataSet

class AlbumsTableViewController: UITableViewController {
    
    var photoIndex = 0
    var albums: [GraphAPI.Album] = []
    var profileViewController: PhotoSource?
    
    let disposeBag = DisposeBag()
    var reachabilityObserver: AnyObject?
    private var authStateDidChangeListenerHandle: AuthStateDidChangeListenerHandle?
    private var albumsViewModel: FacebookAlbumsViewModel = FacebookAlbumsViewModel.shared
    
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
        
        loadFacebookAlbums()
    }
    
    @objc func loadFacebookAlbums() {
        albumsViewModel.getAlbumsFromFacebook().then { albums in
            self.albums = albums ?? []
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        authStateDidChangeListenerHandle = Auth.auth().addStateDidChangeListener { auth, user in
            if user == nil {
                self.present(LoginViewController(), animated: true, completion: nil)
            }
        }
        startMonitoringReachability()
        checkReachability()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopMonitoringReachability()
        Auth.auth().removeStateDidChangeListener(authStateDidChangeListenerHandle!)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
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
