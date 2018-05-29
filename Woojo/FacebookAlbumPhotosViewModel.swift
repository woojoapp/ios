//
// Created by Edouard Goossens on 13/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import Foundation
import Promises

class FacebookAlbumPhotosViewModel {
    static let shared = FacebookAlbumPhotosViewModel()

    private init() {}

    func setPhoto(position: Int, data: Data) -> Promise<String> {
        return UserProfileRepository.shared.setPhoto(data: data, position: position)
    }

    func getPhotos(albumId: String) -> Promise<[GraphAPI.Album.Photo]?> {
        return FacebookRepository.shared.getAlbumPhotos(albumId: albumId)
    }

    func isBigEnough(photo: GraphAPI.Album.Photo, for size: User.Profile.Photo.Size) -> Bool {
        let biggerImages = photo.images.filter { self.isBiggerThan(image: $0, size: size) }
        return biggerImages.count > 0
    }

    private func isBiggerThan(image: GraphAPI.Album.Photo.Image, size: User.Profile.Photo.Size) -> Bool {
        if let width = image.width,
           let minWidth = User.Profile.Photo.sizes[size],
           let height = image.height,
           let minHeight = User.Profile.Photo.sizes[size] {
            return width > minWidth && height > minHeight
        }
        return false
    }

    func getSmallestBigEnoughImage(photo: GraphAPI.Album.Photo, size: User.Profile.Photo.Size) -> GraphAPI.Album.Photo.Image? {
        let biggerImages = photo.images.filter{ self.isBiggerThan(image: $0, size: size) }
        if biggerImages.count == 0 {
            print("Couldn't find an image big enough to fit format")
            return nil
        }
        // Images that have a missing width or height will be filtered out by "isBiggerThan"
        let best = biggerImages.min { $0.width! * $0.height! < $1.width! * $1.height! }
        return best
    }

    private func hasSize(image: GraphAPI.Album.Photo.Image) -> Bool {
        return image.width != nil && image.height != nil
    }

    func getBiggestImage(photo: GraphAPI.Album.Photo) -> GraphAPI.Album.Photo.Image? {
        let biggestImage = photo.images
                .filter{ self.hasSize(image: $0) }
                .max { $0.width! * $0.height! < $1.width! * $1.height! }
        return biggestImage
    }
}
