//
//  ProfileViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 07/12/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ProfileViewController: UITableViewController, UITextViewDelegate, UICollectionViewDelegate {
    
    @IBOutlet weak var profilePhotoImageView: ProfilePhotoImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var bioTableViewCell: BioTableViewCell!
    @IBOutlet weak var photosCollectionView: UICollectionView!
    @IBOutlet weak var tapGestureRecognizer: UITapGestureRecognizer!
    
    let stubPhotos = [User.Profile.Photo(profile: User.current.value?.profile)]
    
    let disposeBag = DisposeBag()
    fileprivate let bioTextViewPlaceholderText = "Say something about yourself..."
    
    // Photos collection view properties
    fileprivate let photoCount: CGFloat = 6
    fileprivate let reuseIdentifier = "ProfilePhotoCell"
    fileprivate let itemsPerRow: CGFloat = 3
    fileprivate let sectionInsets = UIEdgeInsets(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0)
    
    fileprivate var previousBio: String?
    
    @IBAction func dismiss(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupDataSources()
        setupBioTextView()
    }
    
    func setupDataSources() {
        Woojo.User.current.asObservable()
            .flatMap { user -> Observable<UIImage> in
                if let currentUser = user {
                    return currentUser.profile.photo.asObservable()
                } else {
                    return Variable(#imageLiteral(resourceName: "placeholder_40x40")).asObservable()
                }
            }
            .bindTo(profilePhotoImageView.rx.image)
            .addDisposableTo(disposeBag)
        
        Woojo.User.current.asObservable()
            .map{ $0?.profile.displayName }
            .bindTo(nameLabel.rx.text)
            .addDisposableTo(disposeBag)
        
        Woojo.User.current.asObservable()
            .flatMap { user -> Observable<String> in
                if let currentUser = user {
                    return currentUser.profile.description.asObservable()
                } else {
                    return Variable(self.bioTextViewPlaceholderText).asObservable()
                }
            }
            .map{ text -> String in
                if(text == "") {
                    self.bioTableViewCell.bioTextView.textColor = UIColor.lightGray
                    return self.bioTextViewPlaceholderText
                } else {
                    self.bioTableViewCell.bioTextView.textColor = UIColor.black
                    return text
                }
            }
            .bindTo(bioTableViewCell.bioTextView.rx.text)
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
        
        photosCollectionView.delegate = self
        photosCollectionView.dataSource = self
        
    }
    
    func setupBioTextView() {
        bioTableViewCell.bioTextView.delegate = self
        tapGestureRecognizer.addTarget(self, action: #selector(tap))
        tableView.estimatedRowHeight = 70
        bioTableViewCell.bioTextView.rx.text
            .map{ $0?.characters.count }
            .subscribe(onNext: { count in
                self.setBioFooter(count: count)
            }).addDisposableTo(disposeBag)
    }
    
    func setBioFooter(count: Int?) {
        if let count = count {
            let s = count != 249 ? "s" : ""
            self.tableView.footerView(forSection: 0)?.textLabel?.text = "\(max(250 - count, 0)) character\(s) left"
            //self.tableView.footerView(forSection: 0)?.textLabel?.font = UIFont(name: <#T##String#>, size: <#T##CGFloat#>)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updateTableViewHeaderViewHeight()
        self.setBioFooter(count: bioTableViewCell.bioTextView.text.characters.count)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 && indexPath.row == 0 {
            let onePadding = sectionInsets.left
            let paddingSpace = onePadding * (itemsPerRow + 1)
            let availableWidth = tableView.frame.width - paddingSpace
            let widthPerItem = availableWidth / itemsPerRow
            return (photoCount / itemsPerRow) * widthPerItem + 3 * onePadding
        } else {
            return UITableViewAutomaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if section == 0 {
            view.isHidden = true
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        previousBio = textView.text
        if bioTableViewCell.bioTextView.text == bioTextViewPlaceholderText {
            bioTableViewCell.bioTextView.text = ""
            bioTableViewCell.bioTextView.textColor = UIColor.black
        }
        tableView.footerView(forSection: 0)?.isHidden = false
        setBioFooter(count: bioTableViewCell.bioTextView.text.characters.count)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        let newBio = bioTableViewCell.bioTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        Woojo.User.current.value?.profile.setDescription(description: newBio, completion: { error in
            if error != nil {
                self.bioTableViewCell.bioTextView.text = self.previousBio
            }
        })
        self.tableView.footerView(forSection: 0)?.isHidden = true
        if bioTableViewCell.bioTextView.text == "" {
            bioTableViewCell.bioTextView.text = bioTextViewPlaceholderText
            bioTableViewCell.bioTextView.textColor = UIColor.lightGray
        } else {
            bioTableViewCell.bioTextView.text = newBio
            textViewDidChange(bioTableViewCell.bioTextView)
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.characters.count
        return numberOfChars <= 250 || numberOfChars < textView.text.characters.count
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let currentOffset = tableView.contentOffset
        UIView.setAnimationsEnabled(false)
        tableView.beginUpdates()
        tableView.endUpdates()
        UIView.setAnimationsEnabled(true)
        tableView.setContentOffset(currentOffset, animated: false)
    }
    
    func tap(gesture: UITapGestureRecognizer) {
        bioTableViewCell.bioTextView.resignFirstResponder()
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

// MARK: - UICollectionViewDataSource
extension ProfileViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Int(photoCount)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ProfilePhotoCollectionViewCell
        cell.backgroundColor = UIColor.black
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
    }

}

// MARK: - UICollectionViewDelegateFlowLayout
extension ProfileViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = tableView.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
}
