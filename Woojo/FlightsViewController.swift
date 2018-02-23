//
//  FlightsViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 26/01/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import UIKit
import RxSwift

class FlightsViewController: UIViewController, UIGestureRecognizerDelegate {
    let disposeBag = DisposeBag()
    var reachabilityObserver: AnyObject?
    @IBOutlet weak var tipView: UIView!
    @IBOutlet weak var dismissTipButton: UIButton!
    let tipId = "flights"
    @IBOutlet var datePicker: UIDatePicker!
    @IBOutlet var flightNumberPicker: UIPickerView!
    @IBOutlet var iataCodeLabel: UILabel!
    @IBOutlet var flightNumberTextField: UITextField!
    //@IBOutlet var bottomConstraint: NSLayoutConstraint!
    @IBOutlet var tipViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var saveFlightButton: UIButton!
    @IBOutlet var datePickerTapGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet var airlinePickerTapGestureRecognizer: UITapGestureRecognizer!
    
    var airlineData: [Airline]  = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        airlineData = [
            Airline(iataCode: "AF", name: "Air France"),
            Airline(iataCode: "KL", name: "KLM"),
            Airline(iataCode: "AF", name: "Joon"),
            //Airline(iataCode: "SL", name: "Super long and very boring airline name"),
            Airline(iataCode: "TO", name: "Transavia")
        ]
        flightNumberPicker.dataSource = self
        flightNumberPicker.delegate = self
        
        datePickerTapGestureRecognizer.delegate = self
        airlinePickerTapGestureRecognizer.delegate = self
        
        let imageView = UIImageView(image: #imageLiteral(resourceName: "close"))
        imageView.frame = CGRect(x: dismissTipButton.frame.width/2.0, y: dismissTipButton.frame.height/2.0, width: 10, height: 10)
        dismissTipButton.addSubview(imageView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func dismissTip() {
        Woojo.User.current.value?.dismissTip(tipId: self.tipId)
        UIView.beginAnimations("foldHeader", context: nil)
        tipView.isHidden = true
        tipView.subviews.forEach { $0.isHidden = true }
        self.tipViewHeightConstraint.constant = 0
        UIView.commitAnimations()
    }

    @IBAction func hideKeyboard() {
        view.endEditing(true)
        flightNumberTextField.resignFirstResponder()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == datePickerTapGestureRecognizer {
            return true
        } else if gestureRecognizer == airlinePickerTapGestureRecognizer {
            return true
        }
        return false
    }
    
    @objc func keyboardWillShow(_ notification: NSNotification) {
        if let keyboardFrameEnd = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect, let animationDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval, let navigationController = navigationController {
            //bottomConstraint.constant = self.view.frame.size.height - keyboardFrameEnd.origin.y + navigationController.navigationBar.frame.size.height + UIApplication.shared.statusBarFrame.size.height + searchBar.frame.size.height
            UIView.animate(withDuration: animationDuration, animations: {
                self.view.layoutIfNeeded()
            }, completion: { finished in
                
            })
        }
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification) {
        if let animationDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval {
            //bottomConstraint.constant = 0
            UIView.animate(withDuration: animationDuration, animations: {
                self.view.layoutIfNeeded()
            }, completion: { finished in
                
            })
        }
    }
}

extension FlightsViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return airlineData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return airlineData[row].name
    }
    
    /*func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 5
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return airlineData.count
        } else {
            return 11
        }
        
    }*/
    
    /*func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return airlineData[row]
        } else {
            if row == 0 {
                return " "
            } else {
                return String(row - 1)
            }
        }
    }*/
    
    /*func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        if component == 0 {
            let style = NSMutableParagraphStyle()
            style.alignment = NSTextAlignment.right
            return NSMutableAttributedString(string: airlineData[row], attributes: [NSParagraphStyleAttributeName: style])
        } else {
            if row == 0 {
                return NSMutableAttributedString(string: " ")
            } else {
                return NSMutableAttributedString(string: String(row - 1))
            }
        }
    }*/
    
    /*func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        if component > 0 {
            return 22.0
        }
        return view.frame.width - 128.0 - 24.0
    }*/
}

extension FlightsViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        iataCodeLabel.text = airlineData[row].iataCode
    }
}
