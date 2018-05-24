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
import FirebaseAuth
import FirebaseStorage
import PKHUD
import RSKImageCropper

class ProfileViewController: UITableViewController, PhotoSource, AuthStateAware {
    @IBOutlet weak var profilePhotoImageView: ProfilePhotoImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var occupationLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var occupationTextView: UITextView!
    @IBOutlet var photosCollectionView: UICollectionView!
    @IBOutlet weak var tapGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet weak var longPressGestureRecognizer: UILongPressGestureRecognizer!
    
    private let descriptionPlaceholder = R.string.localizable.profileDescriptionPlaceholder()
    private let occupationPlaceholder = R.string.localizable.profileOccupationPlaceholder()
    
    private var uid: String?
    
    private let disposeBag = DisposeBag()
    
    // Photos collection view properties
    fileprivate let photoCount: CGFloat = 6
    fileprivate let reuseIdentifier = "ProfilePhotoCell"
    fileprivate let itemsPerRow: CGFloat = 3
    fileprivate let sectionInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    
    fileprivate var previousBio: String?
    fileprivate var previousOccupation: String?
    var reachabilityObserver: AnyObject?
    var authStateDidChangeListenerHandle: AuthStateDidChangeListenerHandle? = nil
    let imagePickerController = UIImagePickerController()
    var rskImageCropper: RSKImageCropViewController = RSKImageCropViewController()
    
    var cellBeingMoved: UICollectionViewCell?

    private var viewModel = ProfileViewModel()
    private var photos = [Int: StorageReference]()
    
    @IBAction func dismiss(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        bindViewModel()
        
        setupBioTextView()
        setupOccupationTextView()
        imagePickerController.delegate = self
        longPressGestureRecognizer.addTarget(self, action: #selector(longPress))
        profilePhotoImageView.contentMode = .scaleAspectFill
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
        viewModel.uid
            .drive(onNext: { self.uid = $0 })
            .disposed(by: disposeBag)
        
        viewModel.thumbnails
            .drive(onNext: { photos in
                if let main = photos?[0] {
                    self.profilePhotoImageView.sd_setImage(with: main)
                }
                self.photos = photos ?? [:]
                self.photosCollectionView.reloadData()
            }).disposed(by: disposeBag)

        viewModel.nameAge
            .drive(nameLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.city
            .drive(cityLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.description
                .map{ description -> String in
                    if description.isNullOrEmpty {
                        self.descriptionTextView.textColor = UIColor.lightGray
                        return self.descriptionPlaceholder
                    } else {
                        self.descriptionTextView.textColor = UIColor.black
                        return description!
                    }
                }.drive(descriptionTextView.rx.text)
                .disposed(by: disposeBag)
        
        viewModel.description
            .drive(onNext: { _ in
                self.textViewDidChange(self.descriptionTextView)
            })
            .disposed(by: disposeBag)


        viewModel.occupation
            .map{ occupation -> String in
                if occupation.isNullOrEmpty {
                    self.occupationTextView.textColor = UIColor.lightGray
                    return self.occupationPlaceholder
                } else {
                    self.occupationTextView.textColor = UIColor.black
                    return occupation!
                }
            }
            .drive(occupationTextView.rx.text)
            .disposed(by: disposeBag)
    }
    
    func setupBioTextView() {
        descriptionTextView.delegate = self
        tapGestureRecognizer.addTarget(self, action: #selector(tap))
        tapGestureRecognizer.cancelsTouchesInView = false
        tableView.estimatedRowHeight = 70
        descriptionTextView.rx.text
            .map{ $0?.count }
            .subscribe(onNext: { count in
                self.setBioFooter(count: count)
            }).disposed(by: disposeBag)
    }
    
    func setupOccupationTextView() {
        occupationTextView.delegate = self
        occupationTextView.rx.text
            .map{ $0?.count }
            .subscribe(onNext: { count in
                self.setOccupationFooter(count: count)
            }).disposed(by: disposeBag)
    }
    
    func setBioFooter(count: Int?) {
        if let count = count {
            let s = count != 249 ? NSLocalizedString("characters", comment: "") : NSLocalizedString("character", comment: "")
            self.tableView.footerView(forSection: 0)?.textLabel?.text = String(format: NSLocalizedString("%d %@ left", comment: ""), max(250 - count, 0), s)
        }
    }
    
    func setOccupationFooter(count: Int?) {
        if let count = count {
            let s = count != 29 ? NSLocalizedString("characters", comment: "") : NSLocalizedString("character", comment: "")
            self.tableView.footerView(forSection: 1)?.textLabel?.text = String(format: NSLocalizedString("%d %@ left", comment: ""), max(30 - count, 0), s)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updateTableViewHeaderViewHeight()
        self.setBioFooter(count: descriptionTextView.text.count)
        self.setOccupationFooter(count: occupationTextView.text.count)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 2 && indexPath.row == 0 {
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
        } else if section == 1 {
            view.isHidden = true
        } else if let reachable = isReachable(), !reachable, section == 1 {
            view.isHidden = true
        }
    }
    
    @objc func tap(gesture: UITapGestureRecognizer) {
        descriptionTextView.resignFirstResponder()
        occupationTextView.resignFirstResponder()
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
    
    @IBAction func showDetails() {
        if let uid = uid {
            let userDetailsViewController = UserDetailsViewController<User>(uid: uid, userType: User.self)
            navigationController?.pushViewController(userDetailsViewController, animated: true)
        }
    }
    
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
                    let mainIndexPath = IndexPath(row: 0, section: 0)
                    self.photosCollectionView.moveItem(at: indexPath, to: mainIndexPath)
                    self.collectionView(self.photosCollectionView, moveItemAt: indexPath, to: mainIndexPath)
                })
                let removeButton = UIAlertAction(title: NSLocalizedString("Remove", comment: ""), style: .destructive, handler: { (action) -> Void in
                    HUD.show(.progress)
                    self.viewModel.removePhoto(position: indexPath.row).then {
                        self.photosCollectionView.reloadItems(at: [indexPath])
                        HUD.show(.success)
                        HUD.hide(afterDelay: 1.0)
                        Analytics.setUserProperties(properties: ["profile_photo_count": String(self.photos.count)])
                        Analytics.Log(event: "Profile_photo_removed", with: ["photo_count": String(self.photos.count)])
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
                        let albumTableViewController = navigationController.childViewControllers[0] as? FacebookAlbumsViewController {
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
        if let photo = photos[indexPath.row] {
            cell.photo = photo
            cell.imageView.sd_setImage(with: photo)
            cell.imageView.contentMode = .scaleAspectFill
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
        if let photo = photos[sourceIndexPath.row] {
            viewModel.setPhoto(position: destinationIndexPath.row, photo: photo).then {
                Analytics.Log(event: "Profile_photos_reordered", with: ["photo_count": String(self.photos.count)])
            }
        }
        for i in 0..<Int(photoCount) {
            if let cell = collectionView.cellForItem(at: IndexPath(row: i, section: 0)) as? ProfilePhotoCollectionViewCell {
                if let photo = cell.photo {
                    viewModel.setPhoto(position: i, photo: photo).catch { _ in }
                } else {
                    viewModel.removePhoto(position: i).catch { _ in }
                }
            }
        }
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
            if let selectedIndex = photosCollectionView.indexPathsForSelectedItems?[0].row,
               let data = UIImagePNGRepresentation(croppedImage) {
                viewModel.setPhoto(position: selectedIndex, data: data).then { generatedPictureId in
                    self.navigationController?.dismiss(animated: true, completion: nil)
                    HUD.show(.labeledSuccess(title: NSLocalizedString("Success", comment: ""), subtitle: NSLocalizedString("Photo added!", comment: "")))
                    HUD.hide(afterDelay: 1.0)
                    self.photosCollectionView.reloadItems(at: [IndexPath(row: selectedIndex, section: 0)])
                    Analytics.setUserProperties(properties: ["profile_photo_count": String(self.photos.count)])
                    Analytics.Log(event: "Profile_photo_added", with: ["photo_count": String(self.photos.count), "source": "library"])
                }.catch { _ in
                    HUD.show(.labeledError(title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("Failed to add photo", comment: "")))
                    HUD.hide(afterDelay: 1.0)
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
        if textView == descriptionTextView {
            previousBio = textView.text
            if descriptionTextView.text == descriptionPlaceholder {
                descriptionTextView.text = ""
                descriptionTextView.textColor = UIColor.black
            }
            tableView.footerView(forSection: 0)?.isHidden = false
            setBioFooter(count: descriptionTextView.text.count)
        } else if textView == occupationTextView {
            previousOccupation = textView.text
            if occupationTextView.text == occupationPlaceholder {
                occupationTextView.text = ""
                occupationTextView.textColor = UIColor.black
            }
            tableView.footerView(forSection: 1)?.isHidden = false
            setOccupationFooter(count: occupationTextView.text.count)
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == descriptionTextView {
            let newBio = descriptionTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
            viewModel.setDescription(description: newBio).then {
                Analytics.setUserProperties(properties: ["about_character_count": String(newBio.count)])
                Analytics.Log(event: "Profile.about_updated", with: ["character_count": String(newBio.count)])
            }.catch { _ in
                    self.descriptionTextView.text = self.previousBio
            }
            self.tableView.footerView(forSection: 0)?.isHidden = true
            if descriptionTextView.text == "" {
                descriptionTextView.text = descriptionPlaceholder
                descriptionTextView.textColor = UIColor.lightGray
            } else {
                descriptionTextView.text = newBio
                textViewDidChange(descriptionTextView)
            }
        } else {
            let newOccupation = occupationTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
            viewModel.setOccupation(occupation: newOccupation).catch { _ in
                self.occupationTextView.text = self.previousOccupation
            }
            self.tableView.footerView(forSection: 1)?.isHidden = true
            if occupationTextView.text == "" {
                occupationTextView.text = occupationPlaceholder
                occupationTextView.textColor = UIColor.lightGray
            } else {
                occupationTextView.text = newOccupation
                textViewDidChange(occupationTextView)
            }
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.count
        if textView == descriptionTextView {
            return numberOfChars <= 250 || numberOfChars < textView.text.count
        } else if textView == occupationTextView {
            return numberOfChars <= 30 || numberOfChars < textView.text.count
        } else {
            return false
        }
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

