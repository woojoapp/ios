//
//  Constants.swift
//  Woojo
//
//  Created by Edouard Goossens on 22/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation

struct Constants {
    struct Request {
        static let firebaseNode = "requests"
        struct Properties {
            static let type = "type"
            static let uid = "uid"
        }
    }
    
    struct Response {
        static let firebaseNode = "responses"
        struct Properties {
            static let type = "type"
            static let uid = "uid"
            static let data =  "data"
        }
    }
    
    struct User {
        static let firebaseNode = "users"
        struct Properties {
            static let uid = "uid"
            static let fbAppScopedID = "app_scoped_id"
            static let fbAccessToken = "fb_access_token"
        }
        struct Activity {
            static let firebaseNode = "activity"
            static let dateFormat = "yyyy-MM-dd'T'HH:mm:ssxx"
            struct properties {
                struct firebaseNodes {
                    static let lastSeen = "last_seen"
                    static let signUp = "sign_up"
                    static let repliedToPushNotificationsInvite = "replied_to_push_notifications_invite"
                }
            }
        }
        struct Bot {
            static let firebaseNode = "bot"
            struct properties {
                struct firebaseNodes {
                    static let uid = "uid"
                }
            }
        }
        struct CommonEventInfo {
            static let firebaseNode = "events"
            struct firebaseNodes {
                static let name = "name"
                static let rsvpStatus = "rsvp_status"
            }
        }
        struct Device {
            static let firebaseNode = "devices"
            struct properties {
                struct firebaseNodes {
                    static let fcm = "fcm"
                    static let token = "token"
                    static let platform = "platform"
                }
            }
        }
        struct Profile {
            static let firebaseNode = "profile"
            struct Photo {
                static let firebaseNode = "photos"
                struct properties {
                    static let full = "full"
                    static let thumbnail = "thumbnail"
                }
            }
            struct properties {
                struct firebaseNodes {
                    static let firstName = "first_name"
                    static let gender = "gender"
                    static let description = "description"
                    static let city = "city"
                    static let country = "country"
                    static let photoID = "photoID"
                    static let birthday = "birthday"
                }
                struct graphAPIKeys {
                    static let firstName = "first_name"
                    static let gender = "gender"
                    static let description = "description"
                    static let city = "city"
                    static let country = "country"
                    static let photoURL = "photoURL"
                    static let birthday = "birthday"
                }
            }
        }
        struct Candidate {
            static let firebaseNode = "candidates"
            struct properties {
                struct firebaseNodes {
                    static let uid = "uid"
                    static let events = "events"
                    static let friends = "friends"
                    static let pageLikes = "page-likes"
                }
            }
        }
        struct Event {
            static let firebaseNode = "events"
            struct properties {
                struct firebaseNodes {
                    static let id = "id"
                }
            }
        }
        
        struct Recommendations {
            static let firebaseNode = "recommendations"
            struct properties {
                struct events {
                    static let firebaseNode = "events"
                }
            }
        }
        
        struct Preferences {
            static let firebaseNode = "preferences"
            struct properties {
                struct firebaseNodes {
                    static let gender = "gender"
                    static let ageRange = "age_range"
                    static let ageRangeMin = "min"
                    static let ageRangeMax = "max"
                }
            }
        }
        struct Notification {
            static let firebaseNode = "notifications"
            static let dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
            static let maxQueueLength = 10
            struct properties {
                struct firebaseNodes {
                    static let type = "type"
                    static let created = "created"
                    static let displayed = "displayed"
                    static let data = "data"
                }
            }
            struct Interaction {
                struct properties {
                    struct firebaseNodes {
                        static let otherId = "otherId"
                    }
                }
                struct Match {
                    struct announcement {
                        static let title = "New match"
                        static let duration = 2.0
                    }
                }
                struct Message {
                    struct properties {
                        struct firebaseNodes {
                            static let excerpt = "excerpt"
                        }
                    }
                    struct announcement {
                        static let title = "New message"
                        static let duration = 2.0
                    }
                }
            }
        }
        struct Like {
            static let firebaseNode = "likes"
            static let dateFormat = "yyyy-MM-dd'T'HH:mm:ssxx"
            struct properties {
                struct firebaseNodes {
                    static let by = "by"
                    static let on = "on"
                    static let created = "created"
                    static let visible = "visible"
                    static let message = "message"
                }
            }
        }
        struct Match {
            static let firebaseNode = "matches"
            static let dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
            struct properties {
                struct firebaseNodes {
                    static let by = "by"
                    static let on = "on"
                    static let created = "created"
                    static let events = "events"
                    static let friends = "friends"
                    static let pageLikes = "page-likes"
                }
            }
        }
        struct Pass {
            static let firebaseNode = "passes"
            static let dateFormat = "yyyy-MM-dd'T'HH:mm:ssxx"
            struct properties {
                struct firebaseNodes {
                    static let created = "created"
                }
            }
        }
        struct Report {
            static let firebaseNode = "reports"
            static let dateFormat = "yyyy-MM-dd'T'HH:mm:ssxx"
            struct properties {
                struct firebaseNodes {
                    static let by = "by"
                    static let on = "on"
                    static let created = "created"
                    static let message = "message"
                }
            }
        }
        struct Tip {
            static let firebaseNode = "tips"
            static let dateFormat = "yyyy-MM-dd'T'HH:mm:ssxx"
        }
        struct PageLike {
            static let firebaseNode = "page-likes"
            struct properties {
                struct firebaseNodes {
                    static let name = "name"
                    static let id = "id"
                    static let pictureURL = "picture_url"
                }
                struct graphAPIKeys {
                    static let id = "id"
                    static let name = "name"
                    static let picture = "picture"
                    static let pictureData = "data"
                    static let pictureDataURL = "url"
                }
            }
        }
        struct Friend {
            static let firebaseNode = "friends"
            struct properties {
                struct firebaseNodes {
                    static let name = "name"
                    static let id = "id"
                    static let pictureURL = "picture_url"
                }
                struct graphAPIKeys {
                    static let id = "id"
                    static let name = "first_name"
                    static let picture = "picture"
                    static let pictureData = "data"
                    static let pictureDataURL = "url"
                }
            }
        }
    }
    
    struct Album {
        struct properties {
            struct graphAPIKeys {
                static let id = "id"
                static let name = "name"
                static let picture = "picture"
                static let pictureData = "data"
                static let pictureDataURL = "url"
                static let data = "data"
                static let count = "count"
            }
        }
    }
    
    struct Event {
        static let firebaseNode = "events"
        static let dateFormat = "yyyy-MM-dd'T'HH:mm:ssxx"
        static let humanDateFormat = "dd MMM yyyy, HH:mm"
        struct properties {
            struct firebaseNodes {
                static let id = "id"
                static let name = "name"
                static let place = "place"
                static let start = "start_time"
                static let end = "end_time"
                static let pictureURL = "picture_url"
                static let coverURL = "cover_url"
                static let description = "description"
                static let attendingCount = "attending_count"
            }
            struct graphAPIKeys {
                static let id = "id"
                static let name = "name"
                static let place = "place"
                static let start = "start_time"
                static let end = "end_time"
                static let picture = "picture"
                static let pictureData = "data"
                static let pictureDataURL = "url"
                static let cover = "cover"
                static let coverSource = "source"
                static let description = "description"
                static let attendingCount = "attending_count"
                static let rsvpStatus = "rsvp_status"
            }
        }
        struct Place {
            static let firebaseNode = "place"
            static let graphAPIKey = "place"
            struct properties {
                struct firebaseNodes {
                    static let name = "name"
                    static let location = "location"
                }
                struct graphAPIKeys {
                    static let name = "name"
                    static let location = "location"
                }
            }
            struct Location {
                static let firebaseNode = "location"
                struct properties {
                    struct firebaseNodes {
                        static let country = "country"
                        static let city = "city"
                        static let zip = "zip"
                        static let street = "street"
                        static let latitude = "latitude"
                        static let longitude = "longitude"
                        static let name = "name"
                    }
                    struct graphAPIKeys {
                        static let country = "country"
                        static let city = "city"
                        static let zip = "zip"
                        static let street = "street"
                        static let latitude = "latitude"
                        static let longitude = "longitude"
                        static let name = "name"
                    }
                }
            }
        }
    }
    
    struct GraphRequest {
        
        static let fields = "fields"
        static let fieldsSeparator = ","
        
        struct UserProfile {
            static let fieldID = "id"
        }
        
        struct UserProfilePhoto {
            static let fields = "picture.width(3000).height(3000)"
            struct keys {
                static let picture = "picture"
                static let data = "data"
                static let url = "url"
            }
        }
        
        struct UserEvents {
            static let path = "/me/events"
            static let fieldPictureUrl = "picture.type(normal){url}"
            static let fieldCoverSource = "cover{source}"
            struct keys {
                static let data = "data"
            }
        }
        
        struct UserFriends {
            static let path = "/me/friends"
            static let fields = "id,first_name,picture.type(normal){url}"
            struct keys {
                static let data = "data"
            }
        }
        
        struct UserPageLikes {
            static let path = "/me/likes"
            static let fields = "id,name,picture.type(normal){url}"
            struct keys {
                static let data = "data"
            }
        }
        
        struct UserAlbums {
            static let path = "/me/albums"
            static let fields = "id,name,count,picture.type(small){url}"
            struct keys {
                static let data = "data"
            }
        }
        
        struct AlbumPhotos {
            static let path = "/photos"
            static let fields = "id,images"
            struct keys {
                static let data = "data"
                static let id = "id"
                static let images = "images"
                static let imageWidth = "width"
                static let imageHeight = "height"
                static let imageURL = "source"
            }
        }
        
    }
    
}
