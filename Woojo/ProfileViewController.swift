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
import Applozic
import PKHUD
import RSKImageCropper

class ProfileViewController: UITableViewController {
    
    @IBOutlet weak var profilePhotoImageView: ProfilePhotoImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var bioTableViewCell: BioTableViewCell!
    @IBOutlet weak var photosCollectionView: UICollectionView!
    @IBOutlet weak var tapGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet weak var longPressGestureRecognizer: UILongPressGestureRecognizer!
    
    let disposeBag = DisposeBag()
    fileprivate let bioTextViewPlaceholderText = NSLocalizedString("Write something about yourself...", comment: "")
    
    // Photos collection view properties
    fileprivate let photoCount: CGFloat = 6
    fileprivate let reuseIdentifier = "ProfilePhotoCell"
    fileprivate let itemsPerRow: CGFloat = 3
    fileprivate let sectionInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    
    fileprivate var previousBio: String?
    var reachabilityObserver: AnyObject?
    
    let imagePickerController = UIImagePickerController()
    var rskImageCropper: RSKImageCropViewController = RSKImageCropViewController()
    
    var cellBeingMoved: UICollectionViewCell?
    
    @IBAction func dismiss(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupDataSources()
        setupBioTextView()
        imagePickerController.delegate = self
        profilePhotoImageView.contentMode = .scaleAspectFill
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
    
    func setupDataSources() {        
        let userPhotos = User.current.asObservable()
            .flatMap { user -> Observable<[User.Profile.Photo?]> in
                if let currentUser = user {
                    return currentUser.profile.photos.asObservable()
                } else {
                    return Variable([nil]).asObservable()
                }
            }
            
        userPhotos.subscribe(onNext: { photos in
            if let profilePhoto = photos[0] {
                if let image = profilePhoto.images[User.Profile.Photo.Size.thumbnail] {
                    self.profilePhotoImageView.image = image
                } else {
                    profilePhoto.download(size: .thumbnail) {
                        self.profilePhotoImageView.image = profilePhoto.images[User.Profile.Photo.Size.thumbnail]
                    }
                }
            } else {
                self.profilePhotoImageView.image = #imageLiteral(resourceName: "placeholder_40x40")
            }
        })
        .addDisposableTo(disposeBag)
        
        User.current.asObservable()
            .map{ $0?.profile.displayName }
            .bindTo(nameLabel.rx.text)
            .addDisposableTo(disposeBag)
        
        User.current.asObservable()
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
        
        self.longPressGestureRecognizer.addTarget(self, action: #selector(longPress))
    }
    
    func setupBioTextView() {
        bioTableViewCell.bioTextView.delegate = self
        tapGestureRecognizer.addTarget(self, action: #selector(tap))
        tapGestureRecognizer.cancelsTouchesInView = false
        tableView.estimatedRowHeight = 70
        bioTableViewCell.bioTextView.rx.text
            .map{ $0?.count }
            .subscribe(onNext: { count in
                self.setBioFooter(count: count)
            }).addDisposableTo(disposeBag)
    }
    
    func setBioFooter(count: Int?) {
        if let count = count {
            let s = count != 249 ? NSLocalizedString("characters", comment: "") : NSLocalizedString("character", comment: "")
            self.tableView.footerView(forSection: 0)?.textLabel?.text = String(format: NSLocalizedString("%d %@ left", comment: ""), max(250 - count, 0), s)
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
        } else if let reachable = isReachable(), !reachable, section == 1 {
            view.isHidden = true
        }
    }
    
    @objc func tap(gesture: UITapGestureRecognizer) {
        bioTableViewCell.bioTextView.resignFirstResponder()
    }
    
    @objc func longPress(gesture: UILongPressGestureRecognizer) {
        if let reachable = isReachable(), !reachable {
            photosCollectionView.cancelInteractiveMovement()
            return
        }
        
        switch(gesture.state) {
        case UIGestureRecognizerState.began:
            guard let selectedIndexPath = self.photosCollectionView.indexPathForItem(at: gesture.location(in: self.photosCollectionView)) else {
                break
            }
            if selectedIndexPath.row == 0 { return }
            if let cell = self.photosCollectionView.cellForItem(at: selectedIndexPath) as? ProfilePhotoCollectionViewCell {
                if cell.photo == nil {
                    return
                } else {
                    cellBeingMoved = cell
                    photosCollectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
                    cell.layer.shadowOpacity = 0.5
                    cell.layer.shadowRadius = 5.0
                    cell.layer.shadowOffset = CGSize(width: 0, height: 0)
                    cell.layer.masksToBounds = false
                }
            }
        case UIGestureRecognizerState.changed:
            photosCollectionView.updateInteractiveMovementTargetPosition(gesture.location(in: self.photosCollectionView))
        case UIGestureRecognizerState.ended:
            if self.photosCollectionView.indexPathForItem(at: gesture.location(in: self.photosCollectionView)) == nil {
                photosCollectionView.cancelInteractiveMovement()
            } else {
                photosCollectionView.endInteractiveMovement()
            }
            cellBeingMoved?.layer.shadowOpacity = 0.0
            cellBeingMoved?.layer.masksToBounds = true
            cellBeingMoved = nil
        default:
            photosCollectionView.cancelInteractiveMovement()
        }
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

// MARK: - UICollectionViewDelegate

extension ProfileViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let reachable = isReachable(), !reachable { return }
        if indexPath.row == 0 { return }
        if let cell = collectionView.cellForItem(at: indexPath) as? ProfilePhotoCollectionViewCell {
            if cell.photo != nil {
                let actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                let setAsMainButton = UIAlertAction(title: NSLocalizedString("Set as Main Photo", comment: ""), style: .default, handler: { (action) -> Void in
                    /*HUD.show(.progress)
                    User.current.value?.profile.deleteFiles(forPhotoAt: indexPath.row) { _ in
                        User.current.value?.profile.remove(photoAt: indexPath.row) { _ in
                            
                            self.photosCollectionView.reloadItems(at: [indexPath])
                            HUD.show(.success)
                            HUD.hide(afterDelay: 1.0)
                            Analytics.Log(event: Constants.Analytics.Events.PhotoRemoved.name)
                        }
                    }*/
                    let mainIndexPath = IndexPath(row: 0, section: 0)
                    self.photosCollectionView.moveItem(at: indexPath, to: mainIndexPath)
                    self.collectionView(self.photosCollectionView, moveItemAt: indexPath, to: mainIndexPath)
                })
                let removeButton = UIAlertAction(title: NSLocalizedString("Remove", comment: ""), style: .destructive, handler: { (action) -> Void in
                    HUD.show(.progress)
                    User.current.value?.profile.deleteFiles(forPhotoAt: indexPath.row) { _ in
                        User.current.value?.profile.remove(photoAt: indexPath.row) { _ in
                            
                            self.photosCollectionView.reloadItems(at: [indexPath])
                            HUD.show(.success)
                            HUD.hide(afterDelay: 1.0)
                            Analytics.Log(event: Constants.Analytics.Events.PhotoRemoved.name)
                        }
                    }
                })
                let cancelButton = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
                actionSheetController.addAction(setAsMainButton)
                actionSheetController.addAction(removeButton)
                actionSheetController.addAction(cancelButton)
                actionSheetController.popoverPresentationController?.sourceView = self.view
                self.present(actionSheetController, animated: true, completion: nil)
            } else {
                let actionSheetController = UIAlertController(title: NSLocalizedString("Add Photo", comment: ""), message: nil, preferredStyle: .actionSheet)
                
                let facebookButton = UIAlertAction(title: NSLocalizedString("Facebook", comment: ""), style: .default, handler: { (action) -> Void in
                    if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: "FacebookPhotosNavigationController"),
                        let albumTableViewController = navigationController.childViewControllers[0] as? AlbumsTableViewController {
                        albumTableViewController.photoIndex = indexPath.row
                        albumTableViewController.profileViewController = self
                        self.present(navigationController, animated: true, completion: nil)
                    }
                })
                actionSheetController.addAction(facebookButton)
                
                if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                    let libraryButton = UIAlertAction(title: NSLocalizedString("Photo Library", comment: ""), style: .default, handler: { (action) -> Void in
                        self.imagePickerController.allowsEditing = false
                        self.imagePickerController.sourceType = .photoLibrary
                        self.present(self.imagePickerController, animated: true, completion: nil)
                    })
                    actionSheetController.addAction(libraryButton)
                }
                
                /*if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    let cameraButton = UIAlertAction(title: "Camera", style: .default, handler: { (action) -> Void in
                        self.imagePickerController.allowsEditing = false
                        self.imagePickerController.sourceType = .camera
                        self.imagePickerController.setNavigationBarHidden(false, animated: true)
                        self.present(self.imagePickerController, animated: true, completion: nil)
                    })
                    actionSheetController.addAction(cameraButton)
                }*/

                
                let cancelButton = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
                actionSheetController.addAction(cancelButton)
                actionSheetController.popoverPresentationController?.sourceView = self.view
                self.present(actionSheetController, animated: true, completion: nil)
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
        if let photos = User.current.value?.profile.photos.value, let photo = photos[indexPath.row] {
            cell.photo = photo
            cell.imageView.contentMode = .scaleAspectFill
            cell.imageView.image = photo.images[User.Profile.Photo.Size.thumbnail]
            cell.photo?.download(size: .thumbnail) {
                cell.imageView.image = photo.images[User.Profile.Photo.Size.thumbnail]
            }
        } else {
            cell.photo = nil
            cell.imageView.contentMode = .bottomRight
            cell.imageView.image = #imageLiteral(resourceName: "plus")
        }
        cell.imageView.layer.cornerRadius = 12.0
        cell.imageView.layer.masksToBounds = true
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = cell as! ProfilePhotoCollectionViewCell
        cell.photo = nil
        cell.imageView.image = nil
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        if let reachable = isReachable(), !reachable { return false }
        var canMove = false
        if let cell = collectionView.cellForItem(at: indexPath) as? ProfilePhotoCollectionViewCell {
            if cell.photo != nil {
                canMove = true
            }
        }
        if indexPath.row == 0 {
            canMove = false
        }
        return canMove
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if let photos = User.current.value?.profile.photos.value, let photo = photos[sourceIndexPath.row] {
            User.current.value?.profile.set(photo: photo, at: destinationIndexPath.row)
        }
        for i in 0..<Int(photoCount) {
            if let cell = collectionView.cellForItem(at: IndexPath(row: i, section: 0)) as? ProfilePhotoCollectionViewCell {
                if let photo = cell.photo {
                    User.current.value?.profile.set(photo: photo, at: i)
                } else {
                    User.current.value?.profile.remove(photoAt: i)
                }
            }
        }
        Analytics.Log(event: Constants.Analytics.Events.PhotosReordered.name)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return indexPath.row != 0
    }

}

// MARK: - UICollectionViewDelegateFlowLayout

extension ProfileViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = tableView.frame.width - paddingSpace
        let widthPerItem = UIKit.floor(availableWidth / itemsPerRow)
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
}

// MARK: - UIImagePickerControllerDelegate

extension ProfileViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            rskImageCropper = RSKImageCropViewController()
            rskImageCropper.originalImage = pickedImage
            rskImageCropper.maskLayerStrokeColor = UIColor.white
            rskImageCropper.delegate = self
            rskImageCropper.avoidEmptySpaceAroundImage = true
            rskImageCropper.cropMode = .custom
            rskImageCropper.dataSource = self
            let newMoveAndScaleLabel = UILabel()
            newMoveAndScaleLabel.frame = CGRect(x: 0.0, y: 24.0, width: rskImageCropper.view.frame.width, height: 24.0)
            newMoveAndScaleLabel.textAlignment = .center
            newMoveAndScaleLabel.center.x = rskImageCropper.view.center.x
            newMoveAndScaleLabel.text = NSLocalizedString("Move and Scale", comment: "")
            newMoveAndScaleLabel.textColor = .white
            rskImageCropper.moveAndScaleLabel.isHidden = true
            rskImageCropper.view.addSubview(newMoveAndScaleLabel)
            self.imagePickerController.pushViewController(rskImageCropper, animated: true)
        }
    }
}

// MARK: - UINavigationControllerDelegate

extension ProfileViewController: UINavigationControllerDelegate {
    // Required for UIImagePickerController
}


extension ProfileViewController: RSKImageCropViewControllerDataSource {
    func imageCropViewControllerCustomMaskPath(_ controller: RSKImageCropViewController) -> UIBezierPath {
        return UIBezierPath(roundedRect: self.rskImageCropper.maskRect, cornerRadius: 24.0)
    }
    
    func imageCropViewControllerCustomMovementRect(_ controller: RSKImageCropViewController) -> CGRect {
        return self.rskImageCropper.maskRect
    }
    
    func imageCropViewControllerCustomMaskRect(_ controller: RSKImageCropViewController) -> CGRect {
        var width = self.view.frame.width - 32.0
        if width > 500.0 { width = 500.0 }
        let x:CGFloat = 16.0
        var height = width * 16.0 / 9.0
        var y: CGFloat = 16.0
        if let navigationController = self.navigationController {
            let topMargin = UIApplication.shared.statusBarFrame.height + navigationController.navigationBar.frame.height
            var bottomMargin = navigationController.navigationBar.frame.height
            if let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController {
                bottomMargin = mainTabBarController.tabBar.frame.height
            }
            height = self.view.frame.height - topMargin - bottomMargin - 32.0
            y = topMargin + 16.0
        }
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

// MARK: - RSKIMageCropViewControllerDelegate

extension ProfileViewController: RSKImageCropViewControllerDelegate {
    
    func imageCropViewControllerDidCancelCrop(_ controller: RSKImageCropViewController) {
        _ = rskImageCropper.navigationController?.popViewController(animated: true)
    }
    
    func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect) {
        if let reachable = isReachable(), reachable {
            HUD.show(.progress)
            if let selectedIndex = photosCollectionView.indexPathsForSelectedItems?[0].row {
                User.current.value?.profile.setPhoto(photo: croppedImage, id: UUID().uuidString, index: selectedIndex) { photo, error in
                    if error != nil {
                        HUD.show(.labeledError(title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("Failed to add photo", comment: "")))
                        HUD.hide(afterDelay: 1.0)
                    } else {
                        self.navigationController?.dismiss(animated: true, completion: nil)
                        HUD.show(.labeledSuccess(title: NSLocalizedString("Success", comment: ""), subtitle: NSLocalizedString("Photo added!", comment: "")))
                        HUD.hide(afterDelay: 1.0)
                    }
                    self.photosCollectionView.reloadItems(at: [IndexPath(row: selectedIndex, section: 0)])
                    Analytics.Log(event: Constants.Analytics.Events.PhotoAdded.name, with: [Constants.Analytics.Events.PhotoAdded.Parameters.source: "library"])
                }
            }
        } else {
            HUD.show(.labeledError(title: NSLocalizedString("No internet", comment: ""), subtitle: nil))
            HUD.hide(afterDelay: 2.0)
        }
    }
    
}

// MARK: - UITextViewDelegate

extension ProfileViewController: UITextViewDelegate {
    
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
        User.current.value?.profile.setDescription(description: newBio, completion: { error in
            if error != nil {
                self.bioTableViewCell.bioTextView.text = self.previousBio
            } else {
                Analytics.Log(event: Constants.Analytics.Events.AboutUpdated.name)
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
    
}

// MARK: - ReachabilityAware

extension ProfileViewController: ReachabilityAware {
    
    func setReachabilityState(reachable: Bool) {
        self.tableView.footerView(forSection: 1)?.isHidden = !reachable
        for cell in self.photosCollectionView.visibleCells as! [ProfilePhotoCollectionViewCell] where cell.photo == nil {
            cell.imageView.image = (reachable) ? #imageLiteral(resourceName: "plus") : nil
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

