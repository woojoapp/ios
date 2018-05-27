//
//  Notification.swift
//  Woojo
//
//  Created by Edouard Goossens on 23/02/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import FirebaseDatabase
    
enum NotificationType: String, Codable {
    case match
    case message
    //case events
    //case people
}

class Notification: Codable {
    var id: String?
    var type: NotificationType?
    var created: Date?
    var displayed: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case type, created, displayed
    }
}

/*class EventsNotification: Notification {
    var count: Int?
    
    private enum CodingKeys: String, CodingKey {
        case count
    }

    /* init(id: String, created: Date, type: NotificationType, count: Int, displayed: Bool? = nil , data: [String:Any]? = nil) {
        self.count = count
        super.init(id: id, type: type, created: created, displayed: displayed, data: data)
    }

    init(notification: Notification, count: Int) {
        self.count = count
        super.init(id: notification.id, type: notification.type, created: notification.created, displayed: notification.displayed, data: notification.data)
    }

    convenience init?(fromFirebase snapshot: DataSnapshot) {
        if let value = snapshot.value as? [String:Any],
            let notification = Notification(fromFirebase: snapshot),
            let count = value[Constants.User.Notification.Events.properties.firebaseNodes.count] as? Int {
            self.init(notification: notification, count: count)
        } else {
            return nil
        }
    }

    override func toDictionary() -> [String:Any] {
        var dict = super.toDictionary()
        dict[Constants.User.Notification.Events.properties.firebaseNodes.count] = self.count
        return dict
    } */
}

class PeopleNotification: Notification {
    var count: Int?
    
    private enum CodingKeys: String, CodingKey {
        case count
    }

    /* init(id: String, created: Date, type: NotificationType, count: Int, displayed: Bool? = nil , data: [String:Any]? = nil) {
        self.count = count
        super.init(id: id, type: type, created: created, displayed: displayed, data: data)
    }

    init(notification: Notification, count: Int) {
        self.count = count
        super.init(id: notification.id, type: notification.type, created: notification.created, displayed: notification.displayed, data: notification.data)
    }

    convenience init?(fromFirebase snapshot: DataSnapshot) {
        if let value = snapshot.value as? [String:Any],
            let notification = Notification(fromFirebase: snapshot),
            let count = value[Constants.User.Notification.People.properties.firebaseNodes.count] as? Int {
            self.init(notification: notification, count: count)
        } else {
            return nil
        }
    }

    override func toDictionary() -> [String:Any] {
        var dict = super.toDictionary()
        dict[Constants.User.Notification.People.properties.firebaseNodes.count] = self.count
        return dict
    } */
}*/

class InteractionNotification: Notification {
    var otherId: String?
    
    private enum CodingKeys: String, CodingKey {
        case otherId
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try super.init(from: decoder)
        
        otherId = try container.decode(String.self, forKey: .otherId)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(otherId, forKey: .otherId)
    }

    /* init(id: String, created: Date, type: NotificationType, otherId: String, displayed: Bool? = nil , data: [String:Any]? = nil) {
        self.otherId = otherId
        super.init(id: id, type: type, created: created, displayed: displayed, data: data)
    }

    init(notification: Notification, otherId: String) {
        self.otherId = otherId
        super.init(id: notification.id, type: notification.type, created: notification.created, displayed: notification.displayed, data: notification.data)
    }

    convenience init?(fromFirebase snapshot: DataSnapshot) {
        if let value = snapshot.value as? [String:Any],
            let notification = Notification(fromFirebase: snapshot),
            let otherId = value[Constants.User.Notification.Interaction.properties.firebaseNodes.otherId] as? String {
            self.init(notification: notification, otherId: otherId)
        } else {
            return nil
        }
    }

    override func toDictionary() -> [String:Any] {
        var dict = super.toDictionary()
        dict[Constants.User.Notification.Interaction.properties.firebaseNodes.otherId] = self.otherId
        return dict
    } */

}

class MatchNotification: InteractionNotification {

    convenience init?(withIdFrom dataSnapshot: DataSnapshot) {
        self.init(from: dataSnapshot)
        self.id = dataSnapshot.key
    }
    
    /* init(id: String, created: Date, otherId: String, displayed: Bool? = nil , data: [String:Any]? = nil) {
        super.init(id: id, created: created, type: .match, otherId: otherId, displayed: displayed, data: data)
    }

    init(notification: InteractionNotification) {
        super.init(id: notification.id, created: notification.created, type: .match, otherId: notification.otherId, displayed: notification.displayed, data: notification.data)
    }

    convenience init?(fromFirebase snapshot: DataSnapshot) {
        if let notification = InteractionNotification(fromFirebase: snapshot) {
            self.init(notification: notification)
        } else {
            return nil
        }
    } */

}

class MessageNotification: InteractionNotification {
    var excerpt: String?
    
    private enum CodingKeys: String, CodingKey {
        case excerpt
    }
    
    convenience init?(withIdFrom dataSnapshot: DataSnapshot) {
        self.init(from: dataSnapshot)
        self.id = dataSnapshot.key
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try super.init(from: decoder)
        
        excerpt = try container.decode(String.self, forKey: .excerpt)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(excerpt, forKey: .excerpt)
    }
    
    func toString() -> String {
        return "MessageNotification(id=\(id), type=\(type), created=\(created), displayed=\(displayed), otherId=\(otherId), excerpt=\(excerpt))"
    }

    /* init(id: String, created: Date, otherId: String, excerpt: String, displayed: Bool? = nil, data: [String:Any]? = nil) {
        //self.otherId = otherId
        //self.messageId = messageId
        self.excerpt = excerpt
        super.init(id: id, created: created, type: .message, otherId: otherId, displayed: displayed, data: data)
    }

    init(notification: InteractionNotification, excerpt: String) {
        //self.otherId = otherId
        //self.messageId = messageId
        self.excerpt = excerpt
        super.init(id: notification.id, created: notification.created, type: .message, otherId: notification.otherId, displayed: notification.displayed, data: notification.data)
    }

    convenience init?(fromFirebase snapshot: DataSnapshot) {
        if let value = snapshot.value as? [String:Any],
            let notification = InteractionNotification(fromFirebase: snapshot),
            //let otherId = value[Constants.User.Notification.Match.properties.firebaseNodes.otherId] as? String,
            //let messageId = value[Constants.User.Notification.Message.properties.firebaseNodes.messageId] as? String,
            let excerpt = value[Constants.User.Notification.Interaction.Message.properties.firebaseNodes.excerpt] as? String {
            self.init(notification: notification, excerpt: excerpt)
        } else {
            print("messagenotif init returning nil")
            return nil
        }
    }

    override func toDictionary() -> [String:Any] {
        var dict = super.toDictionary()
        //dict[Constants.User.Notification.Interaction.properties.firebaseNodes.otherId] = self.otherId
        //dict[Constants.User.Notification.Message.properties.firebaseNodes.messageId] = self.messageId
        dict[Constants.User.Notification.Interaction.Message.properties.firebaseNodes.excerpt] = self.excerpt
        return dict
    } */

}
