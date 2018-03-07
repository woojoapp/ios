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

class PreferencesViewController: UITableViewController {
    @IBOutlet weak var ageRangeSliderWrapper: UIView!
    @IBOutlet weak var ageRangeMinLabel: UILabel!
    @IBOutlet weak var ageRangeMaxLabel: UILabel!
    @IBOutlet weak var genderSelector: UISegmentedControl!
    
    var ageRange = (min: 20, max: 30)
    var genderSelectorData = [CurrentUser.Preferences.Gender.female, CurrentUser.Preferences.Gender.male, CurrentUser.Preferences.Gender.all]
    
    let ageRangeSlider = RangeSlider(frame: CGRect.zero)
    let disposeBag = DisposeBag()
    
    @IBAction func dismiss(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ageRangeSliderWrapper.addSubview(ageRangeSlider)
        ageRangeSlider.maximumValue = 99.0
        ageRangeSlider.minimumValue = 18.0
        ageRangeMinLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 17.0, weight: UIFont.Weight.regular)
        ageRangeMaxLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 17.0, weight: UIFont.Weight.regular)
        ageRangeSlider.addTarget(self, action: #selector(ageRangeSliderValueChanged(_:)), for: .valueChanged)
        ageRangeSlider.addTarget(self, action: #selector(saveAgeRange(_:)), for: .editingDidEnd)
        setupDataSource()
    }
    
    func setupDataSource() {
        User.current.asObservable()
            .map{ $0?.preferences.ageRange }
            .subscribe(onNext: { ageRange in
                self.ageRange = ageRange ?? (min: 20, max: 30)
                self.ageRangeSlider.upperValue = Double(self.ageRange.max)
                self.ageRangeSlider.lowerValue = Double(self.ageRange.min)
                self.ageRangeSliderValueChanged(self.ageRangeSlider)
            })
            .disposed(by: disposeBag)
        
        User.current.asObservable()
            .map{ $0?.preferences.gender }
            .subscribe(onNext: { gender in
                if let gender = gender, let index = self.genderSelectorData.index(of: gender) {
                    self.genderSelector.selectedSegmentIndex = index
                }
            })
            .disposed(by: disposeBag)
    }
    
    override func viewDidLayoutSubviews() {
        ageRangeSlider.upperValue = Double(ageRange.max)
        ageRangeSlider.lowerValue = Double(ageRange.min)
        ageRangeSlider.frame = CGRect(x: 0.0, y: 0.0, width: ageRangeSliderWrapper.bounds.width, height: 24.0)
    }
    
    @objc func ageRangeSliderValueChanged(_ rangeSlider: RangeSlider) {
        ageRange.min = Int(floor(rangeSlider.lowerValue))
        ageRange.max = Int(ceil(rangeSlider.upperValue))
        ageRangeMinLabel.text = String(ageRange.min)
        ageRangeMaxLabel.text = String(ageRange.max)
    }
    
    func savePreferences() {
        User.current.value?.preferences.save { error in
            if let error = error {
                print("Failed to save preferences \(error.localizedDescription)")
            }
        }
    }
    
    @objc func saveAgeRange(_ rangeSlider: RangeSlider) {
        User.current.value?.preferences.ageRange = ageRange
        savePreferences()
        Analytics.setUserProperties(properties: ["preferred_age_min": String(ageRange.min)])
        Analytics.setUserProperties(properties: ["preferred_age_max": String(ageRange.max)])
        Analytics.Log(event: "Preferences_age_range_updated", with: ["min_age": String(ageRange.min), "max_age": String(ageRange.max)])
    }
    
    @IBAction func saveGender(sender: UISegmentedControl) {
        let gender = genderSelectorData[sender.selectedSegmentIndex]
        User.current.value?.preferences.gender = gender
        savePreferences()
        Analytics.setUserProperties(properties: ["preferred_gender": gender.rawValue])
        Analytics.Log(event: "Preferences_gender_updated", with: ["gender": gender.rawValue])
    }
}
