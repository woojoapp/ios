//
// Created by Edouard Goossens on 11/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import RxSwift
import Promises

class EventbriteRepository {
    static var shared = EventbriteRepository()
    private init() {}

    func getEvents(accessToken: String) -> Promise<[EventbriteEvent]> {
        let url = "\(Constants.User.Integrations.Eventbrite.baseUrl)/users/me/orders?token=\(accessToken)&expand=event,event.venue,event.logo&time_filter=all"
        let request = NSMutableURLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        return Promise<[EventbriteEvent]> { fulfill, reject in
            let requestAPI = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
                if let error = error {
                    reject(EventbriteError.requestFailed(error: error))
                }
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    reject(EventbriteError.httpError(response: httpResponse))
                }
                if error == nil && data != nil {
                    do {
                        print("EVVENTBRITE", data, response)
                        let orderResponse = EventbriteOrderResponse(from: data!)
                        //let dict = orderResponse.orders.reduce(into: [String: Bool](), { $0["eventbrite_\($1.event.id)"] = true })
                        fulfill(orderResponse?.orders.map { $0.event } ?? [])
                    }
                }
            }
            requestAPI.resume()
        }
    }

    enum EventbriteError: Error {
        case requestFailed(error: Error)
        case httpError(response: HTTPURLResponse)
        case jsonDecodeError(error: Error)
    }
}
