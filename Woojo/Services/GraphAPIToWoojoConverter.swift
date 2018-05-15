//
// Created by Edouard Goossens on 09/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import Foundation

class GraphAPIToWoojoConverter {
    static var shared = GraphAPIToWoojoConverter()

    private init() {}

    func convertProfile(graphApiProfile: GraphAPI.Profile?) -> User.Profile? {
        guard let graphApiProfile = graphApiProfile else { return nil }
        let profile = Woojo.User.Profile()
        profile.firstName = graphApiProfile.firstName
        profile.birthday = graphApiProfile.birthday
        profile.gender = graphApiProfile.gender
        profile.location = convertLocation(graphApiLocation: graphApiProfile.location?.location)
        return profile
    }

    func convertLocation(graphApiLocation: GraphAPI.Location?) -> Woojo.Location? {
        guard let graphApiLocation = graphApiLocation else { return nil }
        var location = Woojo.Location()
        location.id = graphApiLocation.id
        location.name = graphApiLocation.name
        location.country = graphApiLocation.country
        location.city = graphApiLocation.city
        location.zip = graphApiLocation.zip
        location.street = graphApiLocation.street
        location.latitude = graphApiLocation.latitude
        location.longitude = graphApiLocation.longitude
        return location
    }

    func convertPageLike(graphApiPageLike: GraphAPI.PageLike?) -> Woojo.PageLike? {
        guard let graphApiPageLike = graphApiPageLike else { return nil }
        let pageLike = Woojo.PageLike()
        pageLike.id = graphApiPageLike.id
        pageLike.name = graphApiPageLike.name
        if let pictureUrl = graphApiPageLike.picture?.data?.url { pageLike.pictureURL = URL(string: pictureUrl) }
        return pageLike
    }

    func convertFriend(graphApiFriend: GraphAPI.Friend?) -> Woojo.Friend? {
        guard let graphApiFriend = graphApiFriend else { return nil }
        let friend = Woojo.Friend()
        friend.id = graphApiFriend.id
        friend.name = graphApiFriend.firstName
        if let pictureUrl = graphApiFriend.picture?.data?.url { friend.pictureURL = URL(string: pictureUrl) }
        return friend
    }

    enum ConversionError: Error {
        case conversionFailed
    }
}
