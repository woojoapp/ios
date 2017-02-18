//
//  PhotoCollectionViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 15/12/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import Applozic
import RSKImageCropper
import PKHUD
import SDWebImage

class PhotoCollectionViewController: UICollectionViewController {
    
    var photoIndex = 0
    var album: Album?
    var photos: [Album.Photo] = []
    var rskImageCropper: RSKImageCropViewController?
    var profileViewController: ProfileViewController?
    
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
        
        self.collectionView?.dataSource = self
        self.collectionView?.delegate = self
        
        loadAlbumPhotos()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! AlbumPhotoCollectionViewCell
        if let image = photos[indexPath.row].getBestImage(size: .thumbnail),
            let url = image.url {
            SDWebImageManager
                .shared()
                .downloadImage(with: url,
                               options: [SDWebImageOptions.cacheMemoryOnly],
                               progress: { (receivedSize: Int, expectedSize: Int) -> Void in
                                DispatchQueue.main.async {
                                    cell.progressIndicator.isHidden = false
                                    cell.progressIndicator.setProgress(Float(receivedSize)/Float(expectedSize), animated: false)
                                }
                },
                               completed: { image, _, _, _, _ in
                                if let image = image {
                                    cell.progressIndicator.isHidden = true
                                    cell.imageView.image = image
                                }
                }
            )
        }        
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //if let image = photos[indexPath.row].getBestImage(size: .full), let url = image.url {
        if let image = photos[indexPath.row].getBiggestImage(), let url = image.url {
            do {
                let data = try Data(contentsOf: url)
                let uiImage = UIImage(data: data)
                if let uiImage = uiImage {
                    rskImageCropper = RSKImageCropViewController(image: uiImage)
                    rskImageCropper?.maskLayerStrokeColor = UIColor.white
                    rskImageCropper?.delegate = self
                    rskImageCropper?.avoidEmptySpaceAroundImage = true
                    rskImageCropper?.cropMode = .square
                    self.navigationController?.pushViewController(rskImageCropper!, animated: true)
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

extension PhotoCollectionViewController: RSKImageCropViewControllerDelegate {
    
    func imageCropViewControllerDidCancelCrop(_ controller: RSKImageCropViewController) {
        _ = rskImageCropper?.navigationController?.popToViewController((rskImageCropper?.parent)!, animated: true)
    }
    
    func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect) {
        HUD.show(.progress)
        if let selectedIndex = collectionView?.indexPathsForSelectedItems?[0].row, let id = photos[selectedIndex].id {
            Woojo.User.current.value?.profile.setPhoto(photo: croppedImage, id: id, index: self.photoIndex) { photo, error in
                if error != nil {
                    HUD.show(.labeledError(title: "Error", subtitle: "Failed to add photo"))
                    HUD.hide(afterDelay: 1.0)
                } else {
                    self.navigationController?.dismiss(animated: true, completion: nil)
                    HUD.show(.labeledSuccess(title: "Success", subtitle: "Photo added!"))
                    HUD.hide(afterDelay: 1.0)
                }
                self.profileViewController?.photosCollectionView.reloadItems(at: [IndexPath(row: self.photoIndex, section: 0)])
            }
        }
    }
    
}
