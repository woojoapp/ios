//
//  AlbumsTableViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 13/12/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import RxSwift

class AlbumsTableViewController: UITableViewController {
    
    var photoIndex = 0
    var albums: [Album] = []
    var profileViewController: ProfileViewController?
    
    let disposeBag = DisposeBag()
    
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
        
        Woojo.User.current.asObservable().subscribe(onNext: { _ in
            self.loadFacebookAlbums()
        }).addDisposableTo(disposeBag)
    }
    
    func loadFacebookAlbums() {
        Woojo.User.current.value?.getAlbumsFromFacebook { albums in
            self.albums = albums
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if albums.count > 0 {
            self.tableView.separatorStyle = .singleLine
            return 1
        } else {
            let messageLabel = UILabel(frame: CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
            messageLabel.text = "No albums found\nPull to refresh"
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
