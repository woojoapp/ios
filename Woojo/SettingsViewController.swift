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
import FirebaseStorageUI
import RxSwift

class SettingsViewController: UITableViewController, AuthStateAware {
    
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var deleteAccountButton: UIButton!    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var profilePhotoImageView: ProfilePhotoImageView!
    
    let disposeBag = DisposeBag()
    var reachabilityObserver: AnyObject?
    private let viewModel = SettingsViewModel()
    var authStateDidChangeListenerHandle: AuthStateDidChangeListenerHandle?

    @IBAction func logout(sender: UIButton) {
        let logoutAlert = UIAlertController(title: NSLocalizedString("Logout", comment: ""), message: NSLocalizedString("Sure you want to logout?", comment: ""), preferredStyle: .alert)
        logoutAlert.addAction(UIAlertAction(title: NSLocalizedString("Logout", comment: ""), style: .default) { _ in
            self.dismiss(animated: true, completion: nil)
            self.viewModel.logOut()
        })
        logoutAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        logoutAlert.popoverPresentationController?.sourceView = self.view
        present(logoutAlert, animated: true)
    }
    
    @IBAction func deleteAccount(sender: UIButton) {
        let deleteAccountAlert = UIAlertController(title: NSLocalizedString("Delete Account", comment: ""), message: NSLocalizedString("Sure you want to delete your account?", comment: ""), preferredStyle: .alert)
        deleteAccountAlert.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive) { _ in
            self.dismiss(animated: true, completion: nil)
            self.viewModel.deleteAccount()
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
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startListeningForAuthStateChange()
        startMonitoringReachability()
        checkReachability()        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopMonitoringReachability()
        stopListeningForAuthStateChange()
    }
    
    func bindViewModel() {
        viewModel.fullMainPicture()
            .drive(onNext: { $0?.download().then { self.profilePhotoImageView.image = $0 } })
            .disposed(by: disposeBag)

        viewModel.firstName
                .drive(nameLabel.rx.text)
                .disposed(by: disposeBag)
        
        viewModel.shortDescription
                .drive(descriptionLabel.rx.text)
                .disposed(by: disposeBag)
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
        viewModel.share(from: self)
    }

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
