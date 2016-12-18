//
//  SettingsViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 03/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import FacebookLogin
import FirebaseAuth
import RxSwift

class SettingsViewController: UITableViewController {
    
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var profilePhotoImageView: ProfilePhotoImageView!
    
    let disposeBag = DisposeBag()
    
    @IBAction func logout(sender: UIButton) {
        let logoutAlert = UIAlertController(title: "Logout", message: "Confirm you want to logout?", preferredStyle: .alert)
        logoutAlert.addAction(UIAlertAction(title: "Logout", style: .default) { _ in
            self.dismiss(animated: true, completion: nil)
            Woojo.User.current.value?.logOut()
        })
        logoutAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(logoutAlert, animated: true)
    }
    
    @IBAction func deleteAccount(sender: UIButton) {
        let deleteAccountAlert = UIAlertController(title: "Delete Account", message: "Confirm you want to delete your account?", preferredStyle: .alert)
        deleteAccountAlert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.dismiss(animated: true, completion: nil)
            Woojo.User.current.value?.deleteAccount()
        })
        deleteAccountAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(deleteAccountAlert, animated: true)
    }
    
    @IBAction func dismiss(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        //self.navigationItem.title = "Settings"
        //self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismiss(sender:)))
        setupDataSource()
    }
    
    func setupDataSource() {
        Woojo.User.current.asObservable()
            .flatMap { user -> Observable<[User.Profile.Photo?]> in
                if let currentUser = user {
                    return currentUser.profile.photos.asObservable()
                } else {
                    return Variable([nil]).asObservable()
                }
            }
            .map { photos -> UIImage in
                if let profilePhoto = photos[0], let image = profilePhoto.images[User.Profile.Photo.Size.full] {
                    return image
                } else {
                    return #imageLiteral(resourceName: "placeholder_40x40")
                }
            }
            .bindTo(profilePhotoImageView.rx.image)
            .addDisposableTo(disposeBag)
        
        Woojo.User.current.asObservable()
            .map{ $0?.profile.displayName }
            .bindTo(nameLabel.rx.text)
            .addDisposableTo(disposeBag)
        
        Woojo.User.current.asObservable()
            .map{
                var description = ""
                if let age = $0?.profile.age {
                    let ageString = String(describing: age)
                    description = ageString
                }
                if let city = $0?.profile.city {
                    description = "\(description), \(city)"
                }
                if let country = $0?.profile.country {
                    description = "\(description) (\(country))"
                }
                return description
            }
            .bindTo(descriptionLabel.rx.text)
            .addDisposableTo(disposeBag)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 200)
    }*/
    
    /*override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UITableViewHeaderFooterView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 200))
        headerView.contentView.backgroundColor = UIColor.white
        let imageView = ProfilePhotoImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        imageView.image = #imageLiteral(resourceName: "icon_rounded")
        headerView.contentView.addSubview(imageView)
        let imageViewCenterHorizontally = NSLayoutConstraint(item: headerView.contentView, attribute: .centerX, relatedBy: .equal, toItem: imageView, attribute: .centerX, multiplier: 1, constant: 0)
        let imageViewCenterVertically = NSLayoutConstraint(item: headerView.contentView, attribute: .centerY, relatedBy: .equal, toItem: imageView, attribute: .centerY, multiplier: 1, constant: 0)
        /*let imageViewWidth = NSLayoutConstraint(item: imageView, attribute: .height, relatedBy: .equal, toItem: headerView, attribute: .height, multiplier: 0.2, constant: 0)
        let imageViewAspectRatio = NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: imageView, attribute: .height, multiplier: 1, constant: 0)*/
        headerView.contentView.addConstraints([imageViewCenterHorizontally, imageViewCenterVertically])
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 100.0
    }*/
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updateTableViewHeaderViewHeight()
    }
    
    @IBOutlet weak var tableHeaderViewWrapper: UIView!
    
    private func updateTableViewHeaderViewHeight() {
        // Add where so we don't keep calling this if the heights are the same
        if let tableHeaderView = self.tableView.tableHeaderView, self.tableHeaderViewWrapper.frame.height != tableHeaderView.frame.height {
            // Grab the frame out of tableHeaderView
            var headerViewFrame = tableHeaderView.frame
            
            // Set the headerViewFrame's height to be the wrapper's height,
            // dynamically calculated using constraints
            headerViewFrame.size.height = self.tableHeaderViewWrapper.frame.size.height
            
            // Assign the frame of the tableHeaderView to be the
            // headerViewFrame we created above with its updated height
            tableHeaderView.frame = headerViewFrame
            
            // Apply these changes in the next run loop iteration
            DispatchQueue.main.async {
                UIView.beginAnimations("tableHeaderView", context: nil);
                self.tableView.tableHeaderView = self.tableView.tableHeaderView;
                UIView.commitAnimations()
            }
        }
    }

}
