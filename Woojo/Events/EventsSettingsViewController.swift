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
    private var viewModel = EventsSettingsViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupDataSource()
        //disableFacebookIntegration()
    }
    
    @IBAction func dismiss(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func setupDataSource() {
        viewModel
            .isEventbriteIntegrated
            .drive(eventbriteIntegrationSwitch.rx.isOn)
            .disposed(by: disposeBag)
        
        viewModel
            .isFacebookIntegrated
            .drive(facebookIntegrationSwitch.rx.isOn)
            .disposed(by: disposeBag)
    }
    
    @IBAction func switchEventSources(sender: UISwitch) {
        switch sender {
        case eventbriteIntegrationSwitch:
            switchEventbriteIntegration(on: eventbriteIntegrationSwitch.isOn)
        case facebookIntegrationSwitch:
            switchFacebookIntegration(on: facebookIntegrationSwitch.isOn)
        default: ()
        }
    }
    
    private func disableFacebookIntegration() {
        facebookIntegrationContentView.alpha = 0.3
        facebookIntegrationIconImageView.image = facebookIntegrationIconImageView.image?.desaturate()
    }
    
    /*private func displayFacebookAlert() {
        let alert = UIAlertController(title: NSLocalizedString("Currently unavailable", comment: ""), message: NSLocalizedString("Due to temporary changes in Facebook\'s privacy policy, your events are inaccessible at this time.\n\nThis feature will be re-activated when access is restored.", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }*/
    
    private func switchEventbriteIntegration(on: Bool) {
        if on {
            let navigationController = UINavigationController()
            navigationController.pushViewController(EventbriteLoginViewController(), animated: false)
            self.present(navigationController, animated: true, completion: nil)
        } else {
            viewModel.removeEventbriteIntegration().catch { _ in }
        }
    }
    
    private func switchFacebookIntegration(on: Bool) {
        if on {
            viewModel.syncFacebookEvents(viewController: self).catch { _ in self.facebookIntegrationSwitch.isOn = false }
        } else {
            viewModel.removeFacebookIntegration().catch { _ in }
        }
    }
    
}
