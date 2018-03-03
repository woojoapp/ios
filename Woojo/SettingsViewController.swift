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
    @IBOutlet weak var deleteAccountButton: UIButton!    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var profilePhotoImageView: ProfilePhotoImageView!
    
    let disposeBag = DisposeBag()
    var reachabilityObserver: AnyObject?
    
    @IBAction func logout(sender: UIButton) {
        let logoutAlert = UIAlertController(title: NSLocalizedString("Logout", comment: ""), message: NSLocalizedString("Sure you want to logout?", comment: ""), preferredStyle: .alert)
        logoutAlert.addAction(UIAlertAction(title: NSLocalizedString("Logout", comment: ""), style: .default) { _ in
            self.dismiss(animated: true, completion: nil)
            Analytics.Log(event: Constants.Analytics.Events.LoggedOut.name)
            User.current.value?.logOut()
        })
        logoutAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        logoutAlert.popoverPresentationController?.sourceView = self.view
        present(logoutAlert, animated: true)
    }
    
    @IBAction func deleteAccount(sender: UIButton) {
        let deleteAccountAlert = UIAlertController(title: NSLocalizedString("Delete Account", comment: ""), message: NSLocalizedString("Sure you want to delete your account?", comment: ""), preferredStyle: .alert)
        deleteAccountAlert.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive) { _ in
            self.dismiss(animated: true, completion: nil)
            User.current.value?.deleteAccount()
        })
        deleteAccountAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        deleteAccountAlert.popoverPresentationController?.sourceView = self.view
        present(deleteAccountAlert, animated: true)
    }
    
    @IBAction func dismiss(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupDataSource()
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
        User.current.asObservable()
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
        
        User.current.asObservable()
            .map{ $0?.profile.displayName }
            .bindTo(nameLabel.rx.text)
            .addDisposableTo(disposeBag)
        
        User.current.asObservable()
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
    
    @IBAction
    func share() {
        User.current.value?.share(from: self)        
    }
    
    /*override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.selectionStyle = .none
        /*cell?.backgroundColor = .white
        cell?.contentView.backgroundColor = .white
        cell?.accessoryView?.backgroundColor = .white*/
    }*/

}

extension SettingsViewController: ReachabilityAware {
    
    func setReachabilityState(reachable: Bool) {
        deleteAccountButton.isEnabled = reachable
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
