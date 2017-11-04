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
import Applozic

class CurrentUser: User {
    
    override var uid: String {
        get {
            return Auth.auth().currentUser!.uid
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
    
    var firebaseAuthUser: FirebaseAuth.User? {
        get {
            return Auth.auth().currentUser
        }
    }
    
    var preferences: Preferences!
    var candidates: [Candidate] = []
    var events: Variable<[Event]> = Variable([])
    var recommendedEvents: Variable<[Event]> = Variable([])
    var notifications: Variable<[Notification]> = Variable([])
    var isLoading: Variable<Bool> = Variable(false)
    var tips: [String:Any]?
    
    init?() {
        if let uid = Auth.auth().currentUser?.uid {
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
        self.stopObservingNotifications()
        self.stopObservingCandidates()
        LoginManager().logOut()
        do {
            try Auth.auth().signOut()
            if (ALUserDefaultsHandler.isLoggedIn()) {
                let alRegisterUserClientService = ALRegisterUserClientService()
                alRegisterUserClientService.logout(completionHandler: { _, _ in
                    print("Logged out Applozic user")
                });
            }
        } catch {
            print("Failed to signOut from Firebase")
        }
        User.current.value = nil
    }
    
    func deleteAccount() {
        ref.removeValue()
        self.logOut()
        Auth.auth().currentUser?.delete(completion: nil)
    }
    func load(completion: (() -> Void)? = nil) {
        
        func finish() {
            let group = DispatchGroup()
            group.enter()
            self.loadData(completion: {
                print("Loaded data", self.botUid)
                group.leave()
            })
            group.enter()
            self.preferences.loadFromFirebase(completion: { _, _ in
                print("Loaded preferences")
                group.leave()
            })
            group.notify(queue: .main, execute: {
                self.profile.startObserving()
                self.profile.startObservingPhotos()
                self.startObservingEvents()
                self.startObservingRecommendedEvents()
                self.startObservingNotifications()
                self.startObservingCandidates()
                self.isLoading.value = false
                print("User loaded.")
                completion?()
            })
        }
        
        User.current.value = self
        isLoading.value = true
        
        activity.loadFromFirebase(completion: { _, _ in
            print("Loaded activity")
            if self.activity.signUp == nil {
                self.performSignUpActions { _ in
                    print("Performed signUp actions")
                    finish()
                }
            } else {
                self.profile.loadFromFirebase(completion: { _, _ in
                    print("Loaded profile")
                    finish()
                })
            }
        })

    }
    
    func performSignUpActions(completion: ((Error?) -> Void)? = nil) {
        profile.updateFromFacebook(completion: { _ in
            print("Updated profile data from Facebook")
            self.profile.updatePhotoFromFacebook(completion: { _ in
                print("Updated profile photo from Facebook")
                self.profile.loadFromFirebase(completion: { _, _ in
                    print("Loaded profile")
                    self.addFacebookEvents() {
                        print("Events added")
                        // Make sure all event ids are written before adding preferences
                        self.preferences.setDefaults()
                        // This will trigger the candidates proposer through it's preferences change listener
                        self.preferences.save { error in
                            if let error = error {
                                print("Failed to save default preferences to Firebase: \(error.localizedDescription)")
                            }
                            let group = DispatchGroup()
                            group.enter()
                            self.activity.setSignUp { _ in group.leave() }
                            group.enter()
                            self.activity.setLastSeen { _ in group.leave() }
                            group.notify(queue: .main, execute: {
                                completion?(nil)
                            })
                        }
                    }
                })
            })
        })
    }
    
    func addFacebookEvents(completion: (() -> Void)? = nil) {
        getEventsFromFacebook { events in
            let saveEventsGroup = DispatchGroup()
            for event in events {
                saveEventsGroup.enter()
                self.add(event: event) { error in
                    if let error = error {
                        print("Failed to add event to User events: \(error.localizedDescription)")
                    }
                    saveEventsGroup.leave()
                }
            }
            saveEventsGroup.notify(queue: .main, execute: {
                completion?()
            })
        }
    }
    
    func loadData(completion: (() -> Void)? = nil) {
        let loadDataGroup = DispatchGroup()
        loadDataGroup.enter()
        ref.child(Constants.User.Bot.firebaseNode).observeSingleEvent(of: .value, with: { snap in
            if let botUid = snap.childSnapshot(forPath: Constants.User.Bot.properties.firebaseNodes.uid).value as? String {
                self.botUid = botUid
            }
            loadDataGroup.leave()
        })
        loadDataGroup.enter()
        ref.child(Constants.User.Tip.firebaseNode).observeSingleEvent(of: .value, with: { snap in
            if let tips = snap.value as? [String:Any] {
                self.tips = tips
            }
            loadDataGroup.leave()
        })
        loadDataGroup.notify(queue: .main, execute: {
            completion?()
        })
    }
    
    // MARK: - Candidates
    
    var candidatesRef: DatabaseReference {
        get {
            return ref.child(Constants.User.Candidate.firebaseNode)
        }
    }
    
    var candidatesDelegate: CandidatesDelegate?
    var isObservingCandidates = false
    
    func startObservingCandidates() {
        isObservingCandidates = true
        candidatesRef.observe(.childAdded, with: { snapshot in
            let candidate = Candidate(snapshot: snapshot, for: self)
            candidate.profile.loadFromFirebase(completion: { _, _ in
                self.candidates.append(candidate)
                self.candidatesDelegate?.didAddCandidate()
            })
        }, withCancel: { error in
            print("Cancelled observing candidates.childAdded: \(error)")
            self.isObservingCandidates = false
        })
        candidatesRef.observe(.childRemoved, with: { snapshot in
            print("CANDIDATE REMOVED", snapshot.key)
            if let index = self.candidates.index(where: { $0.uid == snapshot.key }) {
                self.candidates.remove(at: index)
                self.candidatesDelegate?.didRemoveCandidate(candidateId: snapshot.key, index: index)
            }
        }, withCancel: { error in
            print("Cancelled observing candidates.childRemoved: \(error)")
            self.isObservingCandidates = false
        })
    }
    
    func stopObservingCandidates() {
        candidatesRef.removeAllObservers()
        isObservingCandidates = false
    }
    
    // MARK: - Notifications
    
    var notificationsRef: DatabaseReference {
        get {
            return ref.child(Constants.User.Notification.firebaseNode)
        }
    }
    
    func startObservingNotifications() {
        //isObservingEvents = true
        notificationsRef.observe(.childAdded, with: { snapshot in
            print("childAdded in notifications", snapshot)
            if let typeString = snapshot.childSnapshot(forPath: Constants.User.Notification.properties.firebaseNodes.type).value as? String,
                let type = NotificationType(rawValue: typeString) {
                switch type {
                case .match:
                    print("match")
                    if let matchNotification = MatchNotification(fromFirebase: snapshot) {
                        self.notifications.value.append(matchNotification)
                        if matchNotification.displayed != true {
                            DispatchQueue.main.async {
                                Notifier.shared.schedule(notification: matchNotification)
                            }
                        }
                    }
                case .message:
                    print("message")
                    if let messageNotification = MessageNotification(fromFirebase: snapshot) {
                        print("Parsed", messageNotification.displayed)
                        self.notifications.value.append(messageNotification)
                        if messageNotification.displayed != true {
                            //DispatchQueue.main.async {
                                print("Scheduling", messageNotification.displayed)
                                Notifier.shared.schedule(notification: messageNotification)
                            //}
                        }
                    }
                }
                if let notificationCount = Woojo.User.current.value?.notifications.value.count {
                    UIApplication.shared.applicationIconBadgeNumber = notificationCount
                }
            }
        }, withCancel: { error in
            print("Cancelled observing notifications.childAdded: \(error)")
            //self.isObservingEvents = false
        })
        notificationsRef.observe(.childRemoved, with: { snapshot in
            if let index = self.notifications.value.index(where: { notification in
                return notification.id == snapshot.key
            }) {
                self.notifications.value.remove(at: index)
                if let notificationCount = Woojo.User.current.value?.notifications.value.count {
                    UIApplication.shared.applicationIconBadgeNumber = notificationCount
                }
            }
        }, withCancel: { error in
            print("Cancelled observing notifications.childRemoved: \(error)")
            //self.isObservingEvents = false
        })
    }
    
    func stopObservingNotifications() {
        notificationsRef.removeAllObservers()
        //isObservingEvents = false
    }
    
    /*func listenToNotifications() {
        User.current.asObservable()
            .flatMap { user -> Observable<[CurrentUser.Notification]> in
                if let currentUser = user {
                    return currentUser.notifications.asObservable()
                } else {
                    return Variable([]).asObservable()
                }
            }
            .subscribe(onNext: { notifications in
                
            }).addDisposableTo(disposeBag)
    }*/
    
    // MARK: - Events
    
    var eventsRef: DatabaseReference {
        get {
            return ref.child(Constants.User.Event.firebaseNode)
        }
    }
    
    var isObservingEvents: Bool = false
    
    func startObservingEvents() {
        isObservingEvents = true
        eventsRef.observe(.childAdded, with: { snapshot in
            print("childAdded in events", snapshot)
            Event.get(for: snapshot.key) { event in
                self.append(event: event)
            }
        }, withCancel: { error in
            print("Cancelled observing events.childAdded: \(error)")
            self.isObservingEvents = false
        })
        eventsRef.observe(.childRemoved, with: { snapshot in
            if let index = self.events.value.index(where: { event in
                return event.id == snapshot.key
            }) {
                self.events.value.remove(at: index)
            }
        }, withCancel: { error in
            print("Cancelled observing events.childRemoved: \(error)")
            self.isObservingEvents = false
        })
    }
    
    func stopObservingEvents() {
        eventsRef.removeAllObservers()
        isObservingEvents = false
    }
    
    // MARK: - Recommended Events
    
    var recommendedEventsRef: DatabaseReference {
        get {
            return ref.child(Constants.User.Recommendations.firebaseNode).child(Constants.User.Recommendations.properties.events.firebaseNode)
        }
    }
    
    var isObservingRecommendedEvents: Bool = false
    
    func startObservingRecommendedEvents() {
        isObservingRecommendedEvents = true
        recommendedEventsRef.observe(.value, with: { arraySnapshot in
            print("change in recommended events", arraySnapshot)
            var newArray: [Event] = []
            let group = DispatchGroup()
            for i in 0..<Int(arraySnapshot.childrenCount) {
                if let snapshot = arraySnapshot.children.allObjects[i] as? DataSnapshot,
                    let eventId = snapshot.value as? String {
                    group.enter()
                    Event.get(for: eventId, completion: { (event) in
                        if let event = event {
                            newArray.append(event)
                        }
                        group.leave()
                    })
                }
            }
            group.notify(queue: .main, execute: {
                self.recommendedEvents.value = newArray
            })
        }, withCancel: { error in
            print("Cancelled observing recommendedEvents.childAdded: \(error)")
            self.isObservingRecommendedEvents = false
        })
    }
    
    func requestRecommendedEventsUpdate(completion: (() -> ())?) {
        let request = [
            Constants.Request.Properties.type: "updateRecommendedEvents",
            Constants.Request.Properties.uid: self.uid
        ]
        ref.root.child(Constants.Request.firebaseNode).childByAutoId().setValue(request) { (error, requestRef) in
            let responseRef = self.ref.root.child(Constants.Response.firebaseNode).child(requestRef.key)
            var handle: UInt = 0
            handle = responseRef.observe(.childAdded, with: { _ in
                requestRef.removeValue(completionBlock: { (_, _) in
                    responseRef.removeObserver(withHandle: handle)
                    responseRef.removeValue(completionBlock: { (_, _) in
                        completion?()
                    })
                })
            })
        }
    }
    
    func stopObservingRecommendedEvents() {
        recommendedEventsRef.removeAllObservers()
        isObservingRecommendedEvents = false
    }
    
    // MARK: - Miscellaneous
    
    func getEventsFromFacebook(completion: @escaping (([Event]) -> Void)) {
        var eventsAttendingOrUnsure: [Event] = []
        var eventsNotReplied: [Event] = []
        if AccessToken.current != nil {
            if firebaseAuthUser != nil {
                let connection = GraphRequestConnection()
                let requestsGroup = DispatchGroup()
                requestsGroup.enter()
                let userAttendingAndUnsureEventsGraphRequest = UserEventsGraphRequest()
                connection.add(userAttendingAndUnsureEventsGraphRequest, batchEntryName: nil, completion: { (response, result) in
                    switch result {
                    case .success(let response):
                        eventsAttendingOrUnsure = response.events
                    case .failed(let error):
                        print("UserEventsGraphRequest failed: \(error.localizedDescription)")
                    }
                    requestsGroup.leave()
                })
                requestsGroup.enter()
                let userNotRepliedEventsGraphRequest = UserNotRepliedEventsGraphRequest()
                connection.add(userNotRepliedEventsGraphRequest, batchEntryName: nil, completion: { (response, result) in
                    switch result {
                    case .success(let response):
                        eventsNotReplied = response.events
                    case .failed(let error):
                        print("UserNotRepliedEventsGraphRequest failed: \(error.localizedDescription)")
                    }
                    requestsGroup.leave()
                })
                connection.start()
                requestsGroup.notify(queue: .main, execute: {
                    let events = eventsAttendingOrUnsure + eventsNotReplied
                    completion(events.sorted(by: { $0.start > $1.start }))
                })
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
        ref.child(Constants.User.Properties.fbAccessToken).setValue(AccessToken.current?.authenticationToken) { error, ref in
            self.eventsRef.child(event.id).setValue(event.rsvpStatus, withCompletionBlock: { error, ref in
                if let error = error {
                    print("Failed to add user event: \(error.localizedDescription)")
                    completion?(error)
                } else {
                    print("Waiting")
                    // Wait for the backend app to fetch event data from Facebook - this will return also if the event is already present
                    let nameRef = event.ref.child(Constants.Event.properties.firebaseNodes.name)
                    var listenerHandle: UInt = 0
                    listenerHandle = nameRef.observe(.value, with: { snapshot in
                        print("ADDED CHILD UNDER EVENT", snapshot.key, snapshot.exists())
                        if snapshot.exists() {
                            nameRef.removeObserver(withHandle: listenerHandle)
                            print("Removed observer")
                            if !self.events.value.contains(where: { $0.id == event.id }) {
                                self.append(event: event)
                            }
                            completion?(nil)
                        }
                    })
                }
            })
        }
    }
    
    func append(event: Event?) {
        if let event = event {
            if self.events.value.index(where: { e in
                return e.id == event.id
            }) == nil {
                self.events.value.append(event)
                self.events.value.sort(by: { $0.start > $1.start })
            }
        }
    }
    
    func append(recommendedEvent: Event?) {
        if let event = recommendedEvent {
            if self.recommendedEvents.value.index(where: { e in
                return e.id == event.id
            }) == nil {
                self.recommendedEvents.value.append(event)
                //self.recommendedEvents.value.sort(by: { $0.start > $1.start })
            }
        }
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
    
    func like(candidate uid: String, visible: Bool? = nil, message: String? = nil, completion: ((Error?) -> Void)? = nil) {
        let like = Like(by: self.uid, on: uid, visible: visible, message: message)
        like.save(completion: completion)
    }
    
    func pass(candidate uid: String, completion: ((Error?) -> Void)? = nil) {
        let pass = Pass(by: self.uid, on: uid)
        pass.save(completion: completion)
    }
    
    func dismissTip(tipId: String, completion: ((Error?) -> Void)? = nil) {
        self.ref.child(Constants.User.Tip.firebaseNode).child(tipId).setValue(Event.dateFormatter.string(from: Date())) { (error, _) in
            completion?(error)
        }
    }
}
