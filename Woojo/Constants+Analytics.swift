//
//  Constants+Analytics.swift
//  Woojo
//
//  Created by Edouard Goossens on 05/04/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import Foundation

extension Constants {
    
    struct Analytics {
        struct Events {
            // MARK: - Events
            struct EventAdded {
                static let name = "Events_event_added"
                struct Parameters {
                    static let name = "name"
                    static let id = "id"
                    static let screen = "screen"
                }
            }
            struct EventRemoved {
                static let name = "Events_event_removed"
                struct Parameters {
                    static let name = "name"
                    static let id = "id"
                    static let screen = "screen"
                }
            }
            struct EventSearched {
                static let name = "Events_event_search"
                struct Parameters {
                    static let name = "name"
                }
            }
            struct PlanMade {
                static let name = "plan_made"
                struct Parameters {
                    static let place = "place"
                    static let id = "id"
                    static let screen = "screen"
                }
            }
            // MARK: - Candidates
            struct CandidateLiked {
                static let name = "candidate_liked"
                struct Parameters {
                    static let uid = "uid"
                    static let screen = "screen"
                    static let type = "type"
                }
            }
            struct CandidatePassed {
                static let name = "candidate_passed"
                struct Parameters {
                    static let uid = "uid"
                    static let screen = "screen"
                    static let type = "type"
                }
            }
            struct CandidateDetailsDisplayed {
                static let name = "candidate_details_displayed"
                struct Parameters {
                    static let uid = "uid"
                }
            }
            struct CandidateDetailsPhotoChanged {
                static let name = "candidate_details_photo_changed"
                struct Parameters {
                    static let uid = "uid"
                }
            }
            struct CandidatesDepleted {
                static let name = "candidates_depleted"
            }
            // MARK: - Chats
            struct ChatDisplayed {
                static let name = "chat_displayed"
                struct Parameters {
                    static let uid = "uid"
                    static let otherId = "otherId"
                }
            }
            struct MessageSent {
                static let name = "message_sent"
                struct Parameters {
                    static let by = "by"
                    static let to = "to"
                }
            }
            struct MatchUnmatched {
                static let name = "match_unmatched"
                struct Parameters {
                    static let uid = "uid"
                    static let otherId = "otherId"
                }
            }
            struct MatchReported {
                static let name = "match_reported"
                struct Parameters {
                    static let uid = "uid"
                    static let otherId = "otherId"
                }
            }
            // MARK: - Settings
            struct AboutUpdated {
                static let name = "about_updated"
            }
            struct PhotoAdded {
                static let name = "photo_added"
                struct Parameters {
                    static let source = "source"
                }
            }
            struct PhotoRemoved {
                static let name = "photo_removed"
            }
            struct PhotosReordered {
                static let name = "photos_reordered"
            }
            struct PreferencesGenderUpdated {
                static let name = "preferences_gender_updated"
            }
            struct PreferencesAgeRangeUpdated {
                static let name = "preferences_age_range_updated"
            }
            struct AboutTermsVisited {
                static let name = "about_terms_visited"
            }
            struct AboutPrivacyVisited {
                static let name = "about_privacy_visited"
            }
            struct AboutSafetyVisited {
                static let name = "about_safety_visited"
            }
            struct AboutCreditsVisited {
                static let name = "about_credits_visited"
            }
            struct LoggedOut {
                static let name = "logged_out"
            }
            struct AccountDeleted {
                static let name = "account_deleted"
            }
        }
    }
    
}
