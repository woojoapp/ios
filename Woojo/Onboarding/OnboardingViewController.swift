//
//  OnboardingViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 19/03/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import UIKit
import BWWalkthrough

class OnboardingViewController: BWWalkthroughViewController {
    
    var showCloseAtEnd = false
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()
        prevButton?.layer.cornerRadius = 24
        nextButton?.layer.cornerRadius = 24
        closeButton?.layer.cornerRadius = 24
    }
    
    override func nextPage() {
        view.endEditing(true)
        super.nextPage()
    }
    
    override func prevPage() {
        view.endEditing(true)
        super.prevPage()
    }
    
    override func scrollViewDidScroll(_ sv: UIScrollView) {
        view.endEditing(true)
        super.scrollViewDidScroll(sv)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0 {
                self.view.frame.origin.y += keyboardSize.height
            }
        }
    }
    
    func showCloseButton(show: Bool) {
        super.closeButton?.isHidden = !show
    }
    
    @IBAction func tap(gesture: UITapGestureRecognizer) {
        view.endEditing(true)
    }
}
