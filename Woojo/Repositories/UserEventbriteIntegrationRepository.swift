//
// Created by Edouard Goossens on 10/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import RxSwift
import Promises

class UserEventbriteIntegrationRepository: EventIdsToEventsConversion {
    private let firebaseAuth = Auth.auth()
    private let firebaseDatabase = Database.database()

    static let shared = UserEventbriteIntegrationRepository()
    private init() {}

    private func getUid() -> String { return firebaseAuth.currentUser!.uid }

    private func getUserDatabaseReference(uid: String) -> DatabaseReference {
        return firebaseDatabase
                .reference()
                .child("users")
                .child(uid)
    }

    private func getCurrentUserDatabaseReference() -> DatabaseReference {
        return getUserDatabaseReference(uid: getUid())
    }

    private func getEventbriteIntegrationReference() -> DatabaseReference {
        return getCurrentUserDatabaseReference().child("integrations/eventbrite")
    }

    private func getEventbriteAccessTokenReference() -> DatabaseReference {
        return getEventbriteIntegrationReference().child("access_token")
    }

    private func getEventbriteEventIdsReference() -> DatabaseReference {
        return getEventbriteIntegrationReference().child("events")
    }

    func removeEventbriteIntegration(completionBlock: @escaping (Error?, DatabaseReference) -> Void) {
        getEventbriteIntegrationReference().removeValue(completionBlock: completionBlock)
    }

    func getEventbriteEvents() -> Observable<[Event]> {
        return getEventbriteEventIdsReference()
                .rx_observeEvent(event: .value)
                .flatMap({ self.transformEventIdsToEvents(dataSnapshot: $0, source: .eventbrite) { $0.key } })
    }

    func getEventbriteAccessToken() -> Observable<DataSnapshot> {
        return getEventbriteAccessTokenReference().rx_observeEvent(event: .value)
    }

    func syncEventbriteEvents(completion: @escaping ((Error?) -> Void)) {
        getEventbriteAccessTokenReference().observeSingleEvent(of: .value, with: { (snapshot) in
            if let accessToken = snapshot.value as? String {
                let url = "\(Constants.User.Integrations.Eventbrite.baseUrl)/users/me/orders?token=\(accessToken)&expand=event,event.venue,event.logo&time_filter=all"
                let request = NSMutableURLRequest(url: URL(string: url)!)
                request.httpMethod = "GET"
                let requestAPI = URLSession.shared.dataTask(with: request as URLRequest) {data, response, error in
                    if (error != nil) {
                        completion(error)
                    }
                    if let httpStatus = response as? HTTPURLResponse , httpStatus.statusCode != 200 {
                        print("Error response: \(String(describing: response))")
                    }
                    if error == nil && data != nil {
                        do {
                            let orderResponse = try JSONDecoder().decode(EventbriteOrderResponse.self, from: data!)
                            DispatchQueue.main.async {
                                let dict = orderResponse.orders.reduce(into: [String: Bool](), { $0["eventbrite_\($1.event.id)"] = true })
                                self.writeEventbriteEventIds(eventIds: dict) { error, _ in completion(error) }
                            }
                        } catch {
                            completion(error)
                        }
                    }
                }
                requestAPI.resume()
            }
        })
    }

    private func writeEventbriteEventIds(eventIds: [String: Bool], completion: @escaping (Error?, DatabaseReference) -> Void) {
        getEventbriteEventIdsReference().setValue(eventIds, withCompletionBlock: completion)
    }
}
