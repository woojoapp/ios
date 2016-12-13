//
//  PreferencesViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 04/12/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import NMRangeSlider
import RxSwift

class PreferencesViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var ageRangeSliderWrapper: UIView!
    @IBOutlet weak var ageRangeMinLabel: UILabel!
    @IBOutlet weak var ageRangeMaxLabel: UILabel!
    @IBOutlet weak var genderPicker: UIPickerView!
    
    var ageRange = (min: 20, max: 30)
    var genderPickerData = [CurrentUser.Preferences.Gender.female, CurrentUser.Preferences.Gender.male, CurrentUser.Preferences.Gender.all]
    
    let ageRangeSlider = RangeSlider(frame: CGRect.zero)
    let disposeBag = DisposeBag()
    
    @IBAction func dismiss(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ageRangeSliderWrapper.addSubview(ageRangeSlider)
        ageRangeSlider.maximumValue = 60.0
        ageRangeSlider.minimumValue = 18.0
        ageRangeMinLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 17.0, weight: UIFontWeightRegular)
        ageRangeMaxLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 17.0, weight: UIFontWeightRegular)
        ageRangeSlider.addTarget(self, action: #selector(ageRangeSliderValueChanged(_:)), for: .valueChanged)
        ageRangeSlider.addTarget(self, action: #selector(saveAgeRange(_:)), for: .editingDidEnd)
        setupDataSource()
    }
    
    func setupDataSource() {
        self.genderPicker.dataSource = self
        self.genderPicker.delegate = self
        
        Woojo.User.current.asObservable()
            .map{ $0?.preferences.ageRange }
            .subscribe(onNext: { ageRange in
                self.ageRange = ageRange ?? (min: 20, max: 30)
                self.ageRangeSlider.upperValue = Double(self.ageRange.max)
                self.ageRangeSlider.lowerValue = Double(self.ageRange.min)
                self.ageRangeSliderValueChanged(self.ageRangeSlider)
            })
            .addDisposableTo(disposeBag)
    }
    
    override func viewDidLayoutSubviews() {
        ageRangeSlider.upperValue = Double(ageRange.max)
        ageRangeSlider.lowerValue = Double(ageRange.min)
        ageRangeSlider.frame = CGRect(x: 0.0, y: 0.0, width: ageRangeSliderWrapper.bounds.width, height: 24.0)
    }
    
    func ageRangeSliderValueChanged(_ rangeSlider: RangeSlider) {
        ageRange.min = Int(floor(rangeSlider.lowerValue))
        ageRange.max = Int(ceil(rangeSlider.upperValue))
        ageRangeMinLabel.text = String(ageRange.min)
        ageRangeMaxLabel.text = String(ageRange.max)
    }
    
    func savePreferences() {
        Woojo.User.current.value?.preferences.save { error in
            if let error = error {
                print("Failed to save preferences \(error.localizedDescription)")
            }
        }
    }
    
    func saveAgeRange(_ rangeSlider: RangeSlider) {
        Woojo.User.current.value?.preferences.ageRange = ageRange
        savePreferences()
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        Woojo.User.current.value?.preferences.gender = genderPickerData[row]
        savePreferences()
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 3
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return genderPickerData[row].rawValue.capitalized
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
}
