//
//  AddEventViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 08/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit

class AddEventViewController: UIViewController {
    
    @IBOutlet weak var containerViewA: UIView!
    @IBOutlet weak var containerViewB: UIView!
    @IBOutlet weak var containerViewC: UIView!
    
    @IBAction func showComponent(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            UIView.animate(withDuration: 0.5, animations: {
                self.containerViewA.alpha = 1
                self.containerViewB.alpha = 0
                self.containerViewC.alpha = 0
            })
        } else if sender.selectedSegmentIndex == 1 {
            UIView.animate(withDuration: 0.5, animations: {
                self.containerViewA.alpha = 0
                self.containerViewB.alpha = 1
                self.containerViewC.alpha = 0
            })
        } else if sender.selectedSegmentIndex == 2 {
            UIView.animate(withDuration: 0.5, animations: {
                self.containerViewA.alpha = 0
                self.containerViewB.alpha = 0
                self.containerViewC.alpha = 1
            })
        }
    }
    
    @IBAction func dismiss(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        self.containerViewA.alpha = 1
        self.containerViewB.alpha = 0
        self.containerViewC.alpha = 0
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*func addSubview(subView: UIView, toView parentView: UIView) {
        parentView.addSubview(subView)
        
        var viewBindingsDict = [String: AnyObject]()
        viewBindingsDict["subView"] = subView
        parentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[subView]|", options: [], metrics: nil, views: viewBindingsDict))
        parentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[subView]|", options: [], metrics: nil, views: viewBindingsDict))
    }
    
    func cycleFromViewController(oldViewController: UIViewController, toViewController newViewController: UIViewController) {
        oldViewController.willMove(toParentViewController: nil)
        self.addChildViewController(newViewController)
        self.addSubview(subView: newViewController.view, toView: self.containerView!)
        newViewController.view.alpha = 0
        newViewController.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.5, animations: {
            newViewController.view.alpha = 1
            oldViewController.view.alpha = 0
        },
                                   completion: { finished in
                                    oldViewController.view.removeFromSuperview()
                                    oldViewController.removeFromParentViewController()
                                    newViewController.didMove(toParentViewController: self)
        })
    }*/
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
