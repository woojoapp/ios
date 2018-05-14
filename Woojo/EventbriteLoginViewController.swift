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
    
    @IBOutlet weak var webView: UIWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.delegate = self
        if let url = URL(string: Constants.User.Integrations.Eventbrite.loginUrl) {
            webView.loadRequest(URLRequest(url: url))
        }
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        if let url = webView.request?.url,
            let fragment = url.fragment,
            let range = fragment.range(of: "access_token="){
            let accessToken = String(fragment[range.upperBound...])
            UserEventbriteIntegrationRepository.shared.setEventbriteAccessToken(accessToken: accessToken).then { _ -> Promise<Void> in
                Analytics.setUserProperties(properties: ["integrated_eventbrite": "true"])
                Analytics.Log(event: "Events_integrated_eventbrite")
                return UserEventbriteIntegrationRepository.shared.syncEventbriteEvents()
            }.then {
                self.dismiss()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func dismiss() {
        super.dismiss(animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
