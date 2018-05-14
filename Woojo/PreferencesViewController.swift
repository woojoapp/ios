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
    
    let ageRangeSlider = RangeSlider(frame: CGRect.zero)
    private let disposeBag = DisposeBag()
    private let preferencesViewModel = PreferencesViewModel()
    private var ageRange = Preferences.AgeRange(min: 18, max: 99)
    private var genderSelectorData = [Preferences.Gender.female, Preferences.Gender.male, Preferences.Gender.all]
    
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
        bindViewModel()
    }
    
    func bindViewModel() {
        preferencesViewModel.getAgeRange()
            .subscribe(onNext: { ageRange in
                self.ageRange = ageRange ?? Preferences.AgeRange(min: 18, max: 99)
                self.ageRangeSlider.upperValue = Double(self.ageRange.max)
                self.ageRangeSlider.lowerValue = Double(self.ageRange.min)
                self.ageRangeSliderValueChanged(self.ageRangeSlider)
            })
            .disposed(by: disposeBag)
        
        preferencesViewModel.getGender()
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
        let gender = genderSelectorData[genderSelector.selectedSegmentIndex]
        let preferences = Preferences(gender: gender, ageRange: ageRange)
        preferencesViewModel.setPreferences(preferences: preferences).catch { _ in }
    }
    
    @objc func saveAgeRange(_ rangeSlider: RangeSlider) {
        savePreferences()
        Analytics.setUserProperties(properties: ["preferred_age_min": String(ageRange.min)])
        Analytics.setUserProperties(properties: ["preferred_age_max": String(ageRange.max)])
        Analytics.Log(event: "Preferences_age_range_updated", with: ["min_age": String(ageRange.min), "max_age": String(ageRange.max)])
    }
    
    @IBAction func saveGender(sender: UISegmentedControl) {
        savePreferences()
        let gender = genderSelectorData[genderSelector.selectedSegmentIndex]
        Analytics.setUserProperties(properties: ["preferred_gender": gender.rawValue])
        Analytics.Log(event: "Preferences_gender_updated", with: ["gender": gender.rawValue])
    }
}
