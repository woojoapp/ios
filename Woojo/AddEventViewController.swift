//
//  AddEventViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 08/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import HMSegmentedControl

class AddEventViewController: UIViewController {
    
    @IBOutlet weak var containerViewA: UIView!
    @IBOutlet weak var containerViewB: UIView!
    @IBOutlet weak var containerViewC: UIView!
    @IBOutlet weak var containerViewD: UIView!
    @IBOutlet weak var containerViewE: UIView!
    
    //@IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var segmentedControl: HMSegmentedControl!
    
    @IBOutlet weak var tapGestureRecognizer: UITapGestureRecognizer!
    
    @IBAction func showComponent(sender: HMSegmentedControl) {
        self.containerViewC.endEditing(true)
        self.containerViewD.endEditing(true)
        self.containerViewE.endEditing(true)
        if sender.selectedSegmentIndex == 0 {
            UIView.animate(withDuration: 0.5, animations: {
                self.containerViewA.alpha = 1
                self.containerViewB.alpha = 0
                self.containerViewC.alpha = 0
                self.containerViewD.alpha = 0
                self.containerViewE.alpha = 0
            })
        } else if sender.selectedSegmentIndex == 1 {
            UIView.animate(withDuration: 0.5, animations: {
                self.containerViewA.alpha = 0
                self.containerViewB.alpha = 1
                self.containerViewC.alpha = 0
                self.containerViewD.alpha = 0
                self.containerViewE.alpha = 0
            })
        } else if sender.selectedSegmentIndex == 2 {
            UIView.animate(withDuration: 0.5, animations: {
                self.containerViewA.alpha = 0
                self.containerViewB.alpha = 0
                self.containerViewC.alpha = 1
                self.containerViewD.alpha = 0
                self.containerViewE.alpha = 0
            })
        } else if sender.selectedSegmentIndex == 3 {
            UIView.animate(withDuration: 0.5, animations: {
                self.containerViewA.alpha = 0
                self.containerViewB.alpha = 0
                self.containerViewC.alpha = 0
                self.containerViewD.alpha = 1
                self.containerViewE.alpha = 0
            })
        } else if sender.selectedSegmentIndex == 4 {
            UIView.animate(withDuration: 0.5, animations: {
                self.containerViewA.alpha = 0
                self.containerViewB.alpha = 0
                self.containerViewC.alpha = 0
                self.containerViewD.alpha = 0
                self.containerViewE.alpha = 1
            })
        }
    }
    
    @IBAction func dismiss(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        self.segmentedControl.type = .images
        self.segmentedControl.sectionImages = [#imageLiteral(resourceName: "explore_section"), #imageLiteral(resourceName: "facebook_section"),#imageLiteral(resourceName: "eventbrite_section"), #imageLiteral(resourceName: "search_section"), #imageLiteral(resourceName: "plan_section")]
        self.segmentedControl.sectionSelectedImages = [#imageLiteral(resourceName: "explore_section_selected"), #imageLiteral(resourceName: "facebook_section_selected"),#imageLiteral(resourceName: "eventbrite_section_selected"), #imageLiteral(resourceName: "search_section_selected"), #imageLiteral(resourceName: "plan_section_selected")]
        self.segmentedControl.selectionIndicatorColor = self.view.tintColor
        self.segmentedControl.selectionStyle = .fullWidthStripe
        self.segmentedControl.selectionIndicatorLocation = .up
        self.segmentedControl.selectionIndicatorHeight = 2.0
        self.segmentedControl.titleTextAttributes = [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 12.0)]
        self.segmentedControl.selectedSegmentIndex = 1
        
        self.containerViewA.alpha = 0//1
        self.containerViewB.alpha = 1//0
        self.containerViewC.alpha = 0
        self.containerViewD.alpha = 0
        self.containerViewE.alpha = 0
        super.viewDidLoad()
        tapGestureRecognizer.addTarget(self, action: #selector(tap))
        tapGestureRecognizer.cancelsTouchesInView = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func tap(gesture: UITapGestureRecognizer) {
        self.containerViewC.endEditing(true)
        self.containerViewD.endEditing(true)
        self.containerViewE.endEditing(true)
    }
}
