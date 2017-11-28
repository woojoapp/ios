//
//  PhotoCollectionViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 15/12/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import RSKImageCropper
import PKHUD
import SDWebImage
import DZNEmptyDataSet

class PhotoCollectionViewController: UICollectionViewController {
    
    var photoIndex = 0
    var album: Album?
    var photos: [Album.Photo] = []
    var rskImageCropper: RSKImageCropViewController = RSKImageCropViewController()
    var profileViewController: ProfileViewController?
    var reachabilityObserver: AnyObject?
    
    //@IBOutlet weak var tipView: UIView!
    //@IBOutlet weak var dismissTipButton: UIButton!
    //let tipId = "bigEnoughPhotos"
    //let headerId = "photosHeader"
    
    // Photo collection view properties
    fileprivate let reuseIdentifier = "photoCell"
    fileprivate let itemsPerRow: CGFloat = 3
    fileprivate let sectionInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    
    @IBAction func dismiss(sender: Any?) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView?.refreshControl = UIRefreshControl()
        collectionView?.refreshControl?.addTarget(self, action: #selector(loadAlbumPhotos), for: UIControlEvents.valueChanged)
        
        collectionView?.dataSource = self
        collectionView?.delegate = self
        
        collectionView?.emptyDataSetSource = self
        collectionView?.emptyDataSetDelegate = self
        
        //collectionView?.register(UINib(nibName: "HeaderTipCollectionReusableView", bundle: nil), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerId)
        
        /*let imageView = UIImageView(image: #imageLiteral(resourceName: "close"))
        imageView.frame = CGRect(x: dismissTipButton.frame.width/2.0, y: dismissTipButton.frame.height/2.0, width: 10, height: 10)
        dismissTipButton.addSubview(imageView)*/
        //loadAlbumPhotos()
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
    
    func loadAlbumPhotos() {
        album?.getPhotos { photos in
            self.photos = photos.filter{ $0.isBigEnough(size: .full) }
            self.collectionView?.reloadData()
            self.collectionView?.refreshControl?.endRefreshing()
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    /*override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerId, for: indexPath)
        return headerView
    }*/
    
    /*func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: self.view.frame.width, height: 106.0)
    }*/

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! AlbumPhotoCollectionViewCell
        //cell.imageView.image = nil
        if let image = photos[indexPath.row].getSmallestBigEnoughImage(size: .thumbnail),
            let url = image.url {
            SDWebImageManager
                .shared()
                .downloadImage(with: url,
                               options: [SDWebImageOptions.cacheMemoryOnly],
                               progress: { (receivedSize: Int, expectedSize: Int) -> Void in
                                DispatchQueue.main.async {
                                    cell.progressIndicator.isHidden = false
                                    cell.progressIndicator.setProgress(Float(receivedSize)/Float(expectedSize), animated: true)
                                }
                },
                               completed: { image, _, _, _, _ in
                                if let image = image {
                                    cell.progressIndicator.isHidden = true
                                    /*if !self.photos[indexPath.row].isBigEnough(size: .full) {
                                        cell.alpha = 0.3
                                    }*/
                                    cell.imageView.image = image
                                }
                }
            )
        }        
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        /*if !photos[indexPath.row].isBigEnough(size: .full) {
            return
        }*/
        if let image = photos[indexPath.row].getBiggestImage(), let url = image.url {
            do {
                let data = try Data(contentsOf: url)
                let uiImage = UIImage(data: data)
                if let uiImage = uiImage {
                    rskImageCropper = RSKImageCropViewController()
                    rskImageCropper.originalImage = uiImage
                    rskImageCropper.maskLayerStrokeColor = UIColor.white
                    rskImageCropper.delegate = self
                    rskImageCropper.avoidEmptySpaceAroundImage = true
                    rskImageCropper.cropMode = .custom
                    rskImageCropper.dataSource = self
                    let newMoveAndScaleLabel = UILabel()
                    newMoveAndScaleLabel.frame = CGRect(x: 0.0, y: 24.0, width: rskImageCropper.view.frame.width, height: 24.0)
                    newMoveAndScaleLabel.textAlignment = .center
                    newMoveAndScaleLabel.center.x = rskImageCropper.view.center.x
                    newMoveAndScaleLabel.text = "Move and Scale"
                    newMoveAndScaleLabel.textColor = .white
                    rskImageCropper.moveAndScaleLabel.isHidden = true
                    rskImageCropper.view.addSubview(newMoveAndScaleLabel)
                    self.navigationController?.pushViewController(rskImageCropper, animated: true)
                }
            } catch {
                print("Failed to download full size image from Facebook: \(error.localizedDescription)")
            }
        }
    }

}

// MARK: - UICollectionViewDelegateFlowLayout
extension PhotoCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
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

extension PhotoCollectionViewController: RSKImageCropViewControllerDataSource {
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

extension PhotoCollectionViewController: RSKImageCropViewControllerDelegate {
    
    func imageCropViewControllerDidCancelCrop(_ controller: RSKImageCropViewController) {
        _ = rskImageCropper.navigationController?.popViewController(animated: true)
    }
    
    func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect) {
        if let reachable = isReachable(), reachable {
            HUD.show(.progress)
            //if let selectedIndex = collectionView?.indexPathsForSelectedItems?[0].row/*, let id = photos[selectedIndex].id*/ {
                User.current.value?.profile.setPhoto(photo: croppedImage, id: UUID().uuidString, index: self.photoIndex) { photo, error in
                    if error != nil {
                        HUD.show(.labeledError(title: "Error", subtitle: "Failed to add photo"))
                        HUD.hide(afterDelay: 1.0)
                    } else {
                        self.navigationController?.dismiss(animated: true, completion: nil)
                        HUD.show(.labeledSuccess(title: "Success", subtitle: "Photo added!"))
                        HUD.hide(afterDelay: 1.0)
                    }
                    self.profileViewController?.photosCollectionView.reloadItems(at: [IndexPath(row: self.photoIndex, section: 0)])
                    Analytics.Log(event: Constants.Analytics.Events.PhotoAdded.name, with: [Constants.Analytics.Events.PhotoAdded.Parameters.source: "facebook"])
                }
            //}
        } else {
            HUD.show(.labeledError(title: "No internet", subtitle: nil))
            HUD.hide(afterDelay: 2.0)
        }
    }
    
}

// MARK: - DZNEmptyDataSetSource

extension PhotoCollectionViewController: DZNEmptyDataSetSource {
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Facebook Photos", attributes: Constants.App.Appearance.EmptyDatasets.titleStringAttributes)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "No photos found in this album\n\nPull to refresh", attributes: Constants.App.Appearance.EmptyDatasets.descriptionStringAttributes)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return #imageLiteral(resourceName: "photos")
    }
    
}
// MARK: - DZNEmptyDataSetDelegate

extension PhotoCollectionViewController: DZNEmptyDataSetDelegate {
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
    
}

extension PhotoCollectionViewController: ReachabilityAware {
    
    func setReachabilityState(reachable: Bool) {
        if reachable {
            loadAlbumPhotos()
        } else {
            collectionView?.refreshControl?.endRefreshing()
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
