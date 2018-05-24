//
//  OnboardingPostPhotosViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 19/03/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import FirebaseStorage
import UIKit
import RSKImageCropper
import PKHUD
import RxSwift

class OnboardingPostPhotosViewController: OnboardingPostBaseViewController, PhotoSource {
    
    @IBOutlet weak var photosCollectionView: UICollectionView!
    @IBOutlet weak var longPressGestureRecognizer: UILongPressGestureRecognizer!
    
    // Photos collection view properties
    private let photoCount: CGFloat = 6
    private let reuseIdentifier = "OnboardingPhotoCell"
    private let itemsPerRow: CGFloat = 3
    private let sectionInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    private let viewModel = ProfileViewModel()
    private var photos = [Int: StorageReference]()
    
    let imagePickerController = UIImagePickerController()
    var rskImageCropper: RSKImageCropViewController = RSKImageCropViewController()
    
    var cellBeingMoved: UICollectionViewCell?
    var reloadedOnce = false
    var selectedIndex: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        imagePickerController.delegate = self
        self.longPressGestureRecognizer.addTarget(self, action: #selector(longPress))
        photosCollectionView.delegate = self
        photosCollectionView.dataSource = self
        viewModel.thumbnails
            .drive(onNext: { photos in
                self.photos = photos ?? [:]
                self.photosCollectionView.reloadData()
            }).disposed(by: disposeBag)
    }
    
    @objc func longPress(gesture: UILongPressGestureRecognizer) {
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

}

extension OnboardingPostPhotosViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 { return }
        selectedIndex = indexPath.row
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
                    UserProfileRepository.shared.removePhoto(position: indexPath.row).then {
                        self.photosCollectionView.reloadItems(at: [indexPath])
                        HUD.show(.success)
                        HUD.hide(afterDelay: 1.0)
                        Analytics.setUserProperties(properties: ["profile_photo_count": String(self.photos.count)])
                        Analytics.Log(event: "Onboarding_photo_removed", with: ["photo_count": String(self.photos.count)])
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
                self.photosCollectionView.reloadData() // TODO: REMOVE THIS
                let facebookButton = UIAlertAction(title: NSLocalizedString("Facebook", comment: ""), style: .default, handler: { (action) -> Void in
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let navigationController = storyboard.instantiateViewController(withIdentifier: "FacebookPhotosNavigationController")
                    if let albumTableViewController = navigationController.childViewControllers[0] as? FacebookAlbumsViewController {
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

extension OnboardingPostPhotosViewController: UICollectionViewDataSource {
    
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
            cell.imageView.contentMode = .scaleAspectFill
            cell.imageView.sd_setImage(with: photo)
        } else {
            cell.photo = nil
            cell.imageView.contentMode = .bottomRight
            cell.imageView.image = #imageLiteral(resourceName: "plus")
        }
        cell.imageView.layer.cornerRadius = 12.0
        cell.imageView.layer.masksToBounds = true
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        // if kind == UICollectionElementKindSectionFooter {
            return collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "photoTip", for: indexPath)
        // }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = cell as! ProfilePhotoCollectionViewCell
        cell.photo = nil
        cell.imageView.image = nil
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let size = CGSize(width: photosCollectionView.frame.width, height: 16)
        print("SIZZE", size)
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if let photo = photos[sourceIndexPath.row] {
            viewModel.setPhoto(position: destinationIndexPath.row, photo: photo).then {
                Analytics.Log(event: "Onboarding_photos_reordered", with: ["photo_count": String(self.photos.count)])
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

extension OnboardingPostPhotosViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace - 12
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

extension OnboardingPostPhotosViewController: UIImagePickerControllerDelegate {
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

extension OnboardingPostPhotosViewController: UINavigationControllerDelegate {
    // Required for UIImagePickerController
}


extension OnboardingPostPhotosViewController: RSKImageCropViewControllerDataSource {
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
        let height = width * 16.0 / 9.0 - 72.0
        let y: CGFloat = 72.0
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

// MARK: - RSKIMageCropViewControllerDelegate

extension OnboardingPostPhotosViewController: RSKImageCropViewControllerDelegate {
    
    func imageCropViewControllerDidCancelCrop(_ controller: RSKImageCropViewController) {
        _ = rskImageCropper.navigationController?.popViewController(animated: true)
    }
    
    func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect) {
        HUD.show(.progress)
        // if let selectedIndex = photosCollectionView.indexPathsForSelectedItems?[0].row {
        if let selectedIndex = selectedIndex,
            let data = UIImagePNGRepresentation(croppedImage) {
            viewModel.setPhoto(position: selectedIndex, data: data).then { generatedPictureId in
                self.navigationController?.dismiss(animated: true, completion: nil)
                HUD.show(.labeledSuccess(title: NSLocalizedString("Success", comment: ""), subtitle: NSLocalizedString("Photo added!", comment: "")))
                HUD.hide(afterDelay: 1.0)
                self.photosCollectionView.reloadItems(at: [IndexPath(row: selectedIndex, section: 0)])
                Analytics.setUserProperties(properties: ["profile_photo_count": String(self.photos.count)])
                Analytics.Log(event: "Onboarding_photo_added", with: ["photo_count": String(self.photos.count), "source": "library"])
                _ = self.presentedViewController?.dismiss(animated: true, completion: nil)
            }.catch { _ in
                HUD.show(.labeledError(title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("Failed to add photo", comment: "")))
                HUD.hide(afterDelay: 1.0)
            }
        }
    }
    
}
