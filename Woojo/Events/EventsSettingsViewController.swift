//
//  EventsSettingsViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 30/04/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import UIKit
import RxSwift

class EventsSettingsViewController: UITableViewController {
    
    @IBOutlet weak var facebookIntegrationSwitch: UISwitch!
    @IBOutlet weak var eventbriteIntegrationSwitch: UISwitch!
    @IBOutlet weak var facebookIntegrationContentView: UIView!
    @IBOutlet weak var facebookIntegrationIconImageView: UIImageView!
    private let disposeBag = DisposeBag()
    private var eventsSettingsViewModel = EventsSettingsViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupDataSource()
        disableFacebookIntegration()
    }
    
    @IBAction func dismiss(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func setupDataSource() {
        eventsSettingsViewModel
            .isEventbriteIntegrated()
            .asDriver(onErrorJustReturn: false)
            .drive(eventbriteIntegrationSwitch.rx.isOn)
            .disposed(by: disposeBag)
        
        eventsSettingsViewModel
            .isFacebookIntegrated()
            .asDriver(onErrorJustReturn: false)
            .drive(facebookIntegrationSwitch.rx.isOn)
            .disposed(by: disposeBag)
    }
    
    @IBAction func switchEventSources(sender: UISwitch) {
        switch sender {
        case eventbriteIntegrationSwitch:
            switchEventbriteIntegration(on: eventbriteIntegrationSwitch.isOn)
        case facebookIntegrationSwitch:
            displayFacebookAlert()
            facebookIntegrationSwitch.isOn = false
        default: ()
        }
    }
    
    private func disableFacebookIntegration() {
        facebookIntegrationContentView.alpha = 0.3
        facebookIntegrationIconImageView.image = facebookIntegrationIconImageView.image?.desaturate()
    }
    
    private func displayFacebookAlert() {
        let alert = UIAlertController(title: NSLocalizedString("Currently unavailable", comment: ""), message: NSLocalizedString("Due to temporary changes in Facebook\'s privacy policy, your events are inaccessible at this time.\n\nThis feature will be re-activated when access is restored.", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func switchEventbriteIntegration(on: Bool) {
        if on {
            let eventbriteLoginViewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "EventbriteLoginNavigationViewController") as! UINavigationController
            self.present(eventbriteLoginViewController, animated: true, completion: nil)
        } else {
            eventsSettingsViewModel.removeEventbriteIntegration().catch { _ in }
        }
    }
    
}
