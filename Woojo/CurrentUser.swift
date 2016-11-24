//
//  User.swift
//  Woojo
//
//  Created by Edouard Goossens on 14/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//
//  Represents the currently authenticated user of the app.
//  Data should be kept in sync between Facebook, Firebase and this class.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
//import Atlas
import FacebookCore

class CurrentUser: User {
    
    override var uid: String {
        get {
            return FIRAuth.auth()!.currentUser!.uid
        }
        set {
            super.uid = newValue
        }
    }
    
    override var fbAppScopedID: String? {
        get {
            return "me"
        }
        set {
            super.fbAppScopedID = newValue
        }
    }
    
    var firebaseAuthUser: FIRUser? {
        get {
            return FIRAuth.auth()?.currentUser
        }
    }
    
    var candidates: [Candidate] = []
    var events: [Event] = []
    
    init?() {
        if let uid = FIRAuth.auth()?.currentUser?.uid {
            super.init(uid: uid)
        } else {
            print("Failed to initialize CurrentUser. No UID. Is the user authenticated?")
            return nil
        }
    }
    
    // MARK: - Candidates
    
    var candidatesRef: FIRDatabaseReference {
        get {
            return ref.child(Constants.User.Candidate.firebaseNode)
        }
    }
    
    var isObservingCandidates = false
    var candidatesDelegates: [CandidatesDelegate]?
    
    func startObservingCandidates() {
        isObservingCandidates = true
        candidatesRef.observe(.childAdded, with: { snapshot in
            let candidate = Candidate(uid: snapshot.key, for: self)
            candidate.profile.loadFromFirebase(completion: { _, _ in
                self.candidates.append(candidate)
                // Notify candidates observers
            })
        }, withCancel: { error in
            print("Failed to start observing candidates.childAdded: \(error)")
            self.isObservingCandidates = false
        })
    }
    
    func stopObservingCandidates() {
        candidatesRef.removeAllObservers()
        isObservingCandidates = false
    }
    
    // MARK: - Events
    
    var eventsRef: FIRDatabaseReference {
        get {
            return ref.child(Constants.User.Event.firebaseNode)
        }
    }
    
    var isObservingEvents: Bool = false
    var eventsDelegates: [EventsDelegate]?
    
    func startObservingEvents() {
        isObservingEvents = true
        eventsRef.observe(.childAdded, with: { snapshot in
            Event.get(for: snapshot.key) { event in
                if let event = event {
                    self.events.append(event)
                    // Notify events observers
                }
            }
        }, withCancel: { error in
            print("Failed to start observing events.childAdded: \(error)")
            self.isObservingCandidates = false
        })
        eventsRef.observe(.childRemoved, with: { snapshot in
            if let index = self.events.index(where: { event in
                return event.id == snapshot.key
            }) {
                self.events.remove(at: index)
            }
        }, withCancel: { error in
            print("Failed to start observing events.childRemoved: \(error)")
            self.isObservingCandidates = false
        })
        isObservingCandidates = true
    }
    
    func stopObservingEvents() {
        eventsRef.removeAllObservers()
        isObservingEvents = false
    }
    
    func getEventsFromFacebook(completion: @escaping ([Event]) -> Void) {
        if AccessToken.current != nil {
            if firebaseAuthUser != nil {
                let userEventsGraphRequest = UserEventsGraphRequest()
                userEventsGraphRequest.start { response, result in
                    switch result {
                    case .success(let response):
                        completion(response.events)
                    case .failed(let error):
                        print("UserEventsGraphRequest failed: \(error.localizedDescription)")
                    }
                }
            } else {
                print("Failed to load user events data from Facebook: No authenticated Firebase user.")
            }
        } else {
            print("Failed to load user events from Facebook: No Facebook access token.")
        }
    }
    
}

/*class CurrentUser {
    
    static var uid: String? {
        get {
            return FIRAuth.auth()?.currentUser?.uid
        }
    }
    
    static var ref: FIRDatabaseReference? {
        get {
            if let uid = uid {
                return FIRDatabase.database().reference().child(Constants.User.firebaseNode).child(uid)
            } else {
                return nil
            }
        }
    }
    
    static var firebaseAuthUser: FIRUser? {
        get {
            return FIRAuth.auth()?.currentUser
        }
    }
    
    static var storageRef: FIRStorageReference? {
        get {
            if let uid = uid {
                return FIRStorage.storage().reference().child(Constants.User.firebaseNode).child(uid)
            } else {
                return nil
            }
        }
    }
    
    static var isObserving = false
    
    static func startObserving() {
        self.isObserving = true
        self.Activity.startObserving()
        self.Profile.startObserving()
        self.startObservingEvents()
        self.startObservingCandidates()
    }
    
    static func stopObserving() {
        self.Activity.stopObserving()
        self.Profile.stopObserving()
        self.stopObservingEvents()
        self.stopObservingCandidates()
        self.isObserving = false
    }
    
    // MARK: - Candidates
    
    static var candidatesRef: FIRDatabaseReference? {
        get {
            if let ref = ref {
                return ref.child(Constants.User.Candidate.firebaseNode)
            } else {
                return nil
            }
        }
    }
    
    static var isStartingToObserveCandidates: Bool = false
    static var isObservingCandidates: Bool = false
    static var candidates: [Candidate] = []
    static var candidatesDelegate: CandidatesDelegate?
    
    static func startObservingCandidates() {
        isStartingToObserveCandidates = true
        candidatesRef?.observe(.childAdded, with: { snapshot in
            Candidate.get(for: snapshot.key) { candidate in
                if let candidate = candidate {
                    candidates.append(candidate)
                    candidatesDelegate?.didUpdateCandidates()
                }
            }
        })
        isStartingToObserveCandidates = false
        isObservingCandidates = true
    }
    
    static func stopObservingCandidates() {
        candidatesRef?.removeAllObservers()
        isObservingCandidates = false
    }

    // MARK: - Events
    
    static var eventsRef: FIRDatabaseReference? {
        get {
            if let ref = ref {
                return ref.child(Constants.User.Event.firebaseNode)
            } else {
                return nil
            }
        }
    }
    
    static var isStartingToObserveEvents: Bool = false
    static var isObservingEvents: Bool = false
    static var events: [Event] = []
    static var eventsDelegate: EventsDelegate?
    
    static func startObservingEvents() {
        isStartingToObserveEvents = true
        eventsRef?.observe(.childAdded, with: { snapshot in
            Event.get(for: snapshot.key) { event in
                if let event = event {
                    events.append(event)
                    eventsDelegate?.didUpdateEvents()
                }
            }
        })
        eventsRef?.observe(.childRemoved, with: { snapshot in
            if let index = events.index(where: { event in
                return event.id == snapshot.key
            }) {
                events.remove(at: index)
            }
        })
        isStartingToObserveCandidates = false
        isObservingCandidates = true
    }
    
    static func stopObservingEvents() {
        eventsRef?.removeAllObservers()
        isObservingEvents = false
    }
    
    static func getEventsFromFacebook(completion: @escaping ([Event]) -> Void) {
        if AccessToken.current != nil {
            if firebaseAuthUser != nil {
                let userEventsGraphRequest = UserEventsGraphRequest()
                userEventsGraphRequest.start { response, result in
                    switch result {
                    case .success(let response):
                        completion(response.events)
                    case .failed(let error):
                        print("UserEventsGraphRequest failed: \(error.localizedDescription)")
                    }
                }
            } else {
                print("Failed to load user events data from Facebook: No authenticated Firebase user.")
            }
        } else {
            print("Failed to load user events from Facebook: No Facebook access token.")
        }
    }
    
    // MARK: - Activity
    
    struct Activity {
        
        private static var _activity = Woojo.Activity()
        
        static var ref: FIRDatabaseReference? {
            get {
                if let userRef = CurrentUser.ref {
                    return userRef.child(Constants.User.Activity.firebaseNode)
                } else {
                    return nil
                }
            }
        }
        
        static var lastSeen: Date? {
            get {
                return _activity.lastSeen
            }
            set {
                if let newValue = newValue {
                    ref?.child(Constants.User.Activity.properties.firebaseNodes.lastSeen).setValue(Woojo.Activity.dateFormatter.string(from: newValue))
                }
                _activity.lastSeen = newValue
            }
        }
        
        static var signUp: Date? {
            get {
                return _activity.signUp
            }
            set {
                if let newValue = newValue {
                    ref?.child(Constants.User.Activity.properties.firebaseNodes.signUp).setValue(Woojo.Activity.dateFormatter.string(from: newValue))
                }
                _activity.signUp = newValue
            }
        }
        
        static var isObserving = false
        static func startObserving() {
            ref?.observe(.value, with: { snapshot in
                if let activity = Woojo.Activity.from(firebase: snapshot) {
                    //_activity.lastSeen = activity.lastSeen
                    //_activity.signUp = activity.signUp
                    _activity = activity
                }
            })
            isObserving = true
        }
        
        static func stopObserving() {
            ref?.removeAllObservers()
            isObserving = false
        }
        
    }
    
    // MARK: - Profile
    
    struct Profile {
        
        private static var _profile = Woojo.Profile()
        
        static var observers: [(Woojo.Profile) -> Void] = []
        
        static var displayName: String? {
            get {
                return CurrentUser.firebaseAuthUser?.displayName
            }
            set {
                let profileChangeRequest = CurrentUser.firebaseAuthUser?.profileChangeRequest()
                profileChangeRequest?.displayName = newValue
                profileChangeRequest?.commitChanges { error in
                    if let error = error {
                        print("Failed to update Firebase user profile display name: \(error.localizedDescription)")
                    }
                }
                ref?.child(Constants.User.Profile.properties.firebaseNodes.firstName).setValue(newValue)
                _profile.displayName = newValue
            }
        }
        
        static func photoDownloadURL(completion: @escaping (URL?, Error?) -> Void) {
            if let url = CurrentUser.firebaseAuthUser?.photoURL {
                FIRStorage.storage().reference(forURL: url.absoluteString).downloadURL(completion: completion)
            }
        }
        
        static var gender: Gender? {
            get {
                return _profile.gender
            }
            set {
                ref?.child(Constants.User.Profile.properties.firebaseNodes.gender).setValue(newValue?.rawValue)
                _profile.gender = newValue
            }
        }
        static var ageRange: (min: Int?, max: Int?)
        static var description: String?
        static var city: String?
        static var country: String?
        static var photoID: String?
        
        static var ref: FIRDatabaseReference? {
            get {
                if let userRef = CurrentUser.ref {
                    return userRef.child(Constants.User.Profile.firebaseNode)
                } else {
                    return nil
                }
            }
        }
        
        static var storageRef: FIRStorageReference? {
            get {
                if let userRef = CurrentUser.storageRef {
                    return userRef.child(Constants.User.Profile.firebaseNode)
                } else {
                    return nil
                }
            }
        }
        
        static var isObserving = false
        static func startObserving() {
            ref?.observe(.value, with: { snapshot in
                if let profile = Woojo.Profile.from(firebase: snapshot) {
                    _profile = profile
                    for observer in observers {
                        observer(profile)
                    }
                }
            })
            isObserving = true
        }
        
        static func stopObserving() {
            ref?.removeAllObservers()
            isObserving = false
        }
        
        static func loadDataFromFacebook() {
            if AccessToken.current != nil {
                if firebaseAuthUser != nil {
                    let userProfileGraphRequest = UserProfileGraphRequest()
                    userProfileGraphRequest.start { response, result in
                        switch result {
                        case.success(let response):
                            // Update Firebase with the data loaded from Facebook
                            Profile.displayName = response.profile?.displayName
                            if let responseAsDictionary = response.profile?.toDictionary() {
                                ref?.updateChildValues(responseAsDictionary) { error, _ in
                                    if let error = error {
                                        print("Failed to update user profile in database: \(error)")
                                    }
                                }
                                CurrentUser.ref?.child(Constants.User.Properties.fbAppScopedID).setValue(response.fbAppScopedID)
                            }
                            if Activity.signUp == nil {
                                Activity.signUp = Date()
                            }
                        case .failed(let error):
                            print("UserProfileGraphRequest failed: \(error.localizedDescription) \(AccessToken.current)")
                        }
                    }
                } else {
                    print("Failed to load profile data from Facebook: No authenticated Firebase user.")
                }
            } else {
                print("Failed to load profile data from Facebook: No Facebook access token.")
            }
        }
    
        static func loadPhotoFromFacebook() {
            if AccessToken.current != nil {
                if let user = firebaseAuthUser {
                    let userProfilePhotoGraphRequest = UserProfilePhotoGraphRequest()
                    userProfilePhotoGraphRequest.start { response, result in
                        switch result {
                        case .success(let response):
                            print("Photo URL: \(response.photoURL?.absoluteString)")
                            print("Thumbnail URL: \(response.thumbnailURL?.absoluteString)")
                            if let photoID = response.photoID {
                                ref?.child(Constants.User.Profile.properties.firebaseNodes.photoID).setValue(photoID)
                                if let photoURL = response.photoURL {
                                    let photoRef = storageRef?.child("photos").child(photoID)
                                    DispatchQueue.global().async {
                                        photoRef?.put(try! Data(contentsOf: photoURL), metadata: nil) { metadata, error in
                                            if let error = error {
                                                print("Failed to upload profile photo to Firebase Storage: \(error)")
                                            } else {
                                                let profileChangeRequest = user.profileChangeRequest()
                                                profileChangeRequest.photoURL = metadata?.downloadURL()
                                                profileChangeRequest.commitChanges { error in
                                                    if let error = error {
                                                        print("Failed to update Firebase user profile photo URL: \(error.localizedDescription)")
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                if let thumbnailURL = response.thumbnailURL {
                                    let thumbnailRef = storageRef?.child("thumbnails").child(photoID)
                                    DispatchQueue.global().async {
                                        thumbnailRef?.put(try! Data(contentsOf: thumbnailURL), metadata: nil) { metadata, error in
                                            if let error = error {
                                                print("Failed to upload profile photo to Firebase Storage: \(error)")
                                            }
                                        }
                                    }
                                }
                            }
                        case .failed(let error):
                            print("UserProfilePhotoGraphRequest failed: \(error.localizedDescription)")
                        }
                    }
                } else {
                    print("Failed to load profile photo from Facebook: No authenticated Firebase user.")
                }
            } else {
                print("Failed to load profile photo from Facebook: No Facebook access token.")
            }
        }
    }

}*/
