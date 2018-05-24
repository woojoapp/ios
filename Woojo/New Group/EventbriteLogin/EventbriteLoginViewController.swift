//
//  EventbriteLoginViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 22/02/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import UIKit
import Promises

class EventbriteLoginViewController: UIViewController, UIWebViewDelegate {
    
    var eventbriteLoginView: EventbriteLoginView! {
        return self.view as! EventbriteLoginView
    }
    
    var viewModel: EventbriteLoginViewModel
    
    init() {
        self.viewModel = EventbriteLoginViewModel()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    override func loadView() {
        view = EventbriteLoginView(viewModel: viewModel)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        eventbriteLoginView.webView.delegate = self
        navigationItem.title = R.string.localizable.eventbrite()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismiss(sender:)))
        
        if let url = URL(string: Constants.User.Integrations.Eventbrite.loginUrl) {
            eventbriteLoginView.webView.loadRequest(URLRequest(url: url))
        }
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        if let url = webView.request?.url,
            let fragment = url.fragment,
            let range = fragment.range(of: "access_token=") {
            let accessToken = String(fragment[range.upperBound...])
            viewModel.setEventbriteAccessToken(accessToken: accessToken).then { _ -> Promise<Void> in
                Analytics.setUserProperties(properties: ["integrated_eventbrite": "true"])
                Analytics.Log(event: "Events_integrated_eventbrite")
                return self.viewModel.syncEventbriteEvents()
            }.then { _ in
                self.dismiss(sender: nil)
            }
        }
    }

    @objc func dismiss(sender: Any?) {
        super.dismiss(animated: true, completion: nil)
    }

}
