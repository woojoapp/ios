//
//  AboutWebViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 20/12/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit

class AboutWebViewController: UIViewController {
    
    @IBOutlet weak var webView: UIWebView!
    
    var url: URL?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let url = url {
            self.webView.loadRequest(URLRequest(url: url))
        }
    }
    
    @IBAction func dismiss(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
