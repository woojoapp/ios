//
//  EventbriteLoginViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 22/02/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import UIKit

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
            User.current.value?.setEventbriteAccessToken(accessToken: accessToken, completion: { (error) in
                if error == nil {
                    self.dismiss()
                }
            })
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
