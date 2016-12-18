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

import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import FacebookCore
import FacebookLogin
import RxSwift
import RxCocoa

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
    
    override var fbAccessToken: AccessToken? {
        get {
            return AccessToken.current
        }
        set {
            super.fbAccessToken = newValue
        }
    }
    
    var firebaseAuthUser: FIRUser? {
        get {
            return FIRAuth.auth()?.currentUser
        }
    }
    
    var preferences: Preferences!
    var candidates: [Candidate] = []
    var events: Variable<[Event]> = Variable([])
    var isLoading: Variable<Bool> = Variable(false)
    
    init?() {
        if let uid = FIRAuth.auth()?.currentUser?.uid {
            super.init(uid: uid)
            self.preferences = Preferences(gender: .all, ageRange: (min: 18, max: 60))
        } else {
            print("Failed to initialize CurrentUser. No UID. Is the user authenticated?")
            return nil
        }
    }
    
    func logOut() {
        self.profile.stopObserving()
        self.profile.stopObservingPhotos()
        self.stopObservingEvents()
        self.stopObservingCandidates()
        LoginManager().logOut()
        do {
            try FIRAuth.auth()?.signOut()
        } catch {
            print("Failed to signOut from Firebase")
        }
        Woojo.User.current.value = nil
    }
    
    func deleteAccount() {
        print(ref)
        ref.removeValue()
        self.logOut()
    }
    
    func load(completion: (() -> Void)? = nil) {
        
        func finish() {
            self.profile.startObserving()
            self.profile.startObservingPhotos()
            self.startObservingEvents()
            self.startObservingCandidates()
            self.isLoading.value = false
            print("User loaded.")
            completion?()
        }
        
        print("Starting to load user...")
        Woojo.User.current.value = self
        isLoading.value = true
        let group = DispatchGroup()
        group.enter()
        self.profile.loadFromFirebase(completion: { _, _ in
            print("Loaded profile")
            group.leave()
        })
        group.enter()
        activity.loadFromFirebase(completion: { _, _ in
            print("Loaded activity")
            group.leave()
        })
        group.notify(queue: .main, execute: {
            self.preferences.loadFromFirebase(completion: { _, _ in
                print("Loaded preferences")
                if self.activity.signUp == nil {
                    self.performSignUpActions { _ in
                        print("Performed signUp actions")
                        finish()
                    }
                } else {
                    finish()
                }
            })
        })
    }
    
    func performSignUpActions(completion: ((Error?) -> Void)? = nil) {
        let group = DispatchGroup()
        group.enter()
        profile.updateFromFacebook(completion: { _ in
            print("Updated profile data from Facebook")
            self.profile.updatePhotoFromFacebook(completion: { _ in
                print("Updated profile photo from Facebook")
                self.profile.loadFromFirebase(completion: { _, _ in
                    print("Loaded profile")
                    group.leave()
                })
            })
        })
        group.enter()
        activity.setSignUp { _ in group.leave() }
        group.enter()
        activity.setLastSeen { _ in group.leave() }
        group.enter()
        preferences.setDefaults()
        preferences.save { error in
            if let error = error {
                print("Failed to save default preferences to Firebase: \(error.localizedDescription)")
                group.leave()
            } else {
                group.leave()
            }
        }
        group.enter()
        getEventsFromFacebook { events in
            let saveEventsGroup = DispatchGroup()
            for event in events {
                saveEventsGroup.enter()
                event.save { error in
                    if let error = error {
                        print("Failed to save event to Firebase: \(error.localizedDescription)")
                        saveEventsGroup.leave()
                    } else {
                        self.eventsRef.child(event.id).setValue(true) { error, ref in
                            if let error = error {
                                print("Failed to add event to User events: \(error.localizedDescription)")
                            }
                            saveEventsGroup.leave()
                        }
                    }
                }
            }
            saveEventsGroup.notify(queue: .main, execute: {
                group.leave()
            })
        }
        group.notify(queue: .main, execute: {
            completion?(nil)
        })
    }
    
    // MARK: - Candidates
    
    var candidatesRef: FIRDatabaseReference {
        get {
            return ref.child(Constants.User.Candidate.firebaseNode)
        }
    }
    
    var candidatesDelegate: CandidatesDelegate?
    var isObservingCandidates = false
    
    func startObservingCandidates() {
        isObservingCandidates = true
        candidatesRef.observe(.childAdded, with: { snapshot in
            let candidate = Candidate(uid: snapshot.key, for: self)
            candidate.profile.loadFromFirebase(completion: { _, _ in
                self.candidates.append(candidate)
                self.candidatesDelegate?.didAddCandidate()
            })
        }, withCancel: { error in
            print("Cancelled observing candidates.childAdded: \(error)")
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
    
    func startObservingEvents() {
        isObservingEvents = true
        eventsRef.observe(.childAdded, with: { snapshot in
            Event.get(for: snapshot.key) { event in
                if let event = event {
                    self.events.value.append(event)
                    self.events.value.sort(by: { $0.start > $1.start })
                }
            }
        }, withCancel: { error in
            print("Cancelled observing events.childAdded: \(error)")
            self.isObservingCandidates = false
        })
        eventsRef.observe(.childRemoved, with: { snapshot in
            if let index = self.events.value.index(where: { event in
                return event.id == snapshot.key
            }) {
                self.events.value.remove(at: index)
            }
        }, withCancel: { error in
            print("Cancelled observing events.childRemoved: \(error)")
            self.isObservingCandidates = false
        })
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
    
    func remove(event: Event, completion: ((Error?) -> Void)?) {
        eventsRef.child(event.id).removeValue { error, ref in
            if let error = error {
                print("Failed to remove user event: \(error.localizedDescription)")
            }
            completion?(error)
        }
    }
    
    func add(event: Event, completion: ((Error?) -> Void)?) {
        eventsRef.child(event.id).setValue(true, withCompletionBlock: { error, ref in
            if let error = error {
                print("Failed to add user event: \(error.localizedDescription)")
            }
            completion?(error)
        })
    }
    
    func getAlbumsFromFacebook(completion: @escaping ([Album]) -> Void) {
        if AccessToken.current != nil {
            if firebaseAuthUser != nil {
                let userAlbumsGraphRequest = UserAlbumsGraphRequest()
                userAlbumsGraphRequest.start { response, result in
                    switch result {
                    case .success(let response):
                        completion(response.albums)
                    case .failed(let error):
                        print("UserAlbumsGraphRequest failed: \(error.localizedDescription)")
                    }
                }
            } else {
                print("Failed to load user albums data from Facebook: No authenticated Firebase user.")
            }
        } else {
            print("Failed to load user albums from Facebook: No Facebook access token.")
        }
    }

}
