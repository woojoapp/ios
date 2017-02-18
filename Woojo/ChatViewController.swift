//
//  ChatViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 15/02/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import Applozic

class ChatViewController: ALChatViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ALApplozicSettings.setColorForSendMessages(self.view.tintColor)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.layer.shadowOpacity = 0.0
        self.navigationController?.navigationBar.tintColor = nil
        //self.navigationController?.navigationBar.titleTextAttributes = [:]
    }
    
}
