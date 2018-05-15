//
// Created by Edouard Goossens on 11/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import RxSwift
import Promises

class UserNotificationRepository: BaseRepository {
    static var shared = UserNotificationRepository()
    
    override private init() {
        super.init()
    }

    func getNotifications() -> Observable<[Notification]> {
        return withCurrentUser {
            $0.child("notifications")
                .rx_observeEvent(event: .value)
                .map {
                    $0.children.reduce(into: [Notification]()) {
                        if let notification = self.getTypedNotification(dataSnapshot: $1 as? DataSnapshot) {
                            $0.append(notification)
                        }
                    }
                }
        }
    }
    
    private func getTypedNotification(dataSnapshot: DataSnapshot?) -> Notification? {
        guard let dataSnapshot = dataSnapshot else { return nil }
        if dataSnapshot.hasChild("type") {
            if let type = dataSnapshot.childSnapshot(forPath: "type").value as? String,
                let notificationType = NotificationType(rawValue: type) {
                switch (notificationType) {
                case .events:
                    return EventsNotification(from: dataSnapshot)
                case .match:
                    return MatchNotification(from: dataSnapshot)
                case .message:
                    return MessageNotification(from: dataSnapshot)
                case .people:
                    return PeopleNotification(from: dataSnapshot)
                }
            }
        }
        return nil
    }

    func setNotificationsState(type: String, enabled: Bool) -> Promise<Void> {
        return doWithCurrentUser {
                $0.child("settings")
                    .child("notifications")
                    .child(type)
                    .setValuePromise(value: enabled)
        }
    }

    func getNotificationsState(type: String) -> Observable<Bool> {
        return withCurrentUser {
                $0.child("settings")
                .child("notifications")
                .child(type)
                .rx_observeEvent(event: .value)
                .map { $0.value as? Bool ?? false }
        }
    }

    func deleteAll(otherId: String) -> Promise<Void> {
        return doWithCurrentUser { ref in
            return Promise<Void> { fulfill, reject in
                let queryRef = ref.child("notifications").queryOrdered(byChild: "otherId").queryEqual(toValue: otherId)
                queryRef.observeSingleEvent(of: .value, with: { dataSnapshot in
                    while let childSnapshot = dataSnapshot.children.nextObject() as? DataSnapshot {
                        childSnapshot.ref.removeValue()
                    }
                    queryRef.removeAllObservers()
                    fulfill(())
                })
            }
        }
    }

    func deleteAll(type: String) -> Promise<Void> {
        return doWithCurrentUser { ref in
            return Promise<Void> { fulfill, reject in
                let queryRef = ref.child("notifications").queryOrdered(byChild: "type").queryEqual(toValue: type)
                queryRef.observeSingleEvent(of: .value, with: { dataSnapshot in
                    while let childSnapshot = dataSnapshot.children.nextObject() as? DataSnapshot {
                        childSnapshot.ref.removeValue()
                    }
                    queryRef.removeAllObservers()
                    fulfill(())
                })
            }
        }
    }

    func setDisplayed(notificationId: String) -> Promise<Void> {
        return doWithCurrentUser { $0.child("notifications").child(notificationId).child("displayed").setValuePromise(value: true) }
    }

    func removeNotification(notificationId: String) -> Promise<Void> {
        return doWithCurrentUser { $0.child("notifications").child(notificationId).removeValuePromise() }
    }
    
    func setNotification(notification: Notification) -> Promise<Void> {
        guard let id = notification.id else { return Promise(UserNotificationRepositoryError.notificationIdMissing) }
        return doWithCurrentUser { $0.child("notifications").child(id).setValuePromise(value: notification.dictionary) }
    }
    
    enum UserNotificationRepositoryError: Error {
        case notificationIdMissing
    }
}
