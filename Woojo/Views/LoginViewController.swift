//
//  LoginViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 03/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import FirebaseAuth
import FacebookCore
import FacebookLogin
import RxCocoa
import RxSwift
import TTTAttributedLabel
import Crashlytics
import BWWalkthrough
import Amplitude_iOS

class LoginViewController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var acceptLabel: TTTAttributedLabel!
    @IBOutlet var loginFacebook: UIButton!
    
    private static let PRE_LOGIN_ONBOARDING_COMPLETED = "PRE_LOGIN_ONBOARDING_COMPLETED"
    
    var onboardingViewController: OnboardingViewController?
    private var loginView: UIView?
    private let termsText = R.string.localizable.termsAndConditions()
    private let privacyText = R.string.localizable.privacyPolicy()
    private let slideNames = [
        "onboarding_welcome",
        "onboarding_events",
        "onboarding_swipe",
        "onboarding_login"
    ]
    private let disposeBag = DisposeBag()
    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    
    override var modalTransitionStyle: UIModalTransitionStyle {
        get {
            return .flipHorizontal
        }
        set {
            super.modalTransitionStyle = .flipHorizontal
        }
    }
    
    func showOnboarding() {
        let onboardingStoryboard = UIStoryboard(name: "Onboarding", bundle: nil)
        if let onboarding = onboardingStoryboard.instantiateViewController(withIdentifier: "Onboarding0") as? OnboardingViewController {
            onboardingViewController = onboarding
            let welcome = onboardingStoryboard.instantiateViewController(withIdentifier: "Onboarding_welcome")
            let events = onboardingStoryboard.instantiateViewController(withIdentifier: "Onboarding_events")
            let swipe = onboardingStoryboard.instantiateViewController(withIdentifier: "Onboarding_swipe")
            let login = onboardingStoryboard.instantiateViewController(withIdentifier: "Onboarding_login") as! OnboardingLoginViewController
            
            login.onboardingViewController = onboardingViewController
            login.loginViewController = self
            
            onboarding.delegate = self
            onboarding.add(viewController: welcome)
            onboarding.add(viewController: events)
            onboarding.add(viewController: swipe)
            onboarding.add(viewController: login)
            
            onboarding.modalPresentationStyle = .custom
            onboarding.modalTransitionStyle = .crossDissolve
            
            self.present(onboardingViewController!, animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.isHidden = true

        acceptLabel.delegate = self
        acceptLabel.activeLinkAttributes = [NSAttributedStringKey.foregroundColor: UIColor.darkGray]
        acceptLabel.linkAttributes = [NSAttributedStringKey.foregroundColor: UIColor.darkGray, NSAttributedStringKey.underlineStyle: 1]
        
        loginFacebook.layer.cornerRadius = 10
        
        if let acceptString = acceptLabel.text {
            let acceptNSString = NSString(string: acceptString)
            let termsRange = acceptNSString.range(of: termsText)
            if let termsURLString = Application.remoteConfig.configValue(forKey: Constants.App.RemoteConfig.Keys.termsURL).stringValue,
                let termsURL = URL(string: termsURLString) {
                acceptLabel.addLink(to: termsURL, with: termsRange)
            }
            
            let privacyRange = acceptNSString.range(of: privacyText)
            if let privacyURLString = Application.remoteConfig.configValue(forKey: Constants.App.RemoteConfig.Keys.privacyURL).stringValue,
                let privacyURL = URL(string: privacyURLString) {
                acceptLabel.addLink(to: privacyURL, with: privacyRange)
            }
            
        }
        
        let userDefaults = UserDefaults.standard
        if !userDefaults.bool(forKey: LoginViewController.PRE_LOGIN_ONBOARDING_COMPLETED) {
            loginFacebook.isHidden = true
            acceptLabel.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !UserDefaults.standard.bool(forKey: LoginViewController.PRE_LOGIN_ONBOARDING_COMPLETED) {
            showOnboarding()
        } else {
            acceptLabel.isHidden = false
        }
    }
    
    func setWorking(working: Bool) {
        loginFacebook.isHidden = working
        if working {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
    @IBAction func login() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(true, forKey: LoginViewController.PRE_LOGIN_ONBOARDING_COMPLETED)
        userDefaults.synchronize()
        Analytics.setUserProperties(properties: ["pre_login_onboarded": "true"])
        Analytics.Log(event: "Onboarding_pre_complete")
        setWorking(working: true)
        LoginViewModel.shared.loginWithFacebook(viewController: self).then { _ in
            self.dismiss(animated: true, completion: {
                self.setWorking(working: false)
            })
        }.catch { error in
            self.setWorking(working: false)
            if let loginError = error as? LoginManager.LoginError {
                if case let .facebookPermissionsDeclined(permissions) = loginError {
                        Analytics.Log(event: "Account_log_in_missing_permissions", with: permissions)
                        self.showDeclinedPermissionsErrorDialog()
                }
            }
        }
    }

    private func showDeclinedPermissionsErrorDialog() {
        let alert = UIAlertController(title: R.string.localizable.missingPermissionsTitle(), message: R.string.localizable.missingPermissionsMessage(), preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: R.string.localizable.missingPermissionsOk(), style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true)
    }
    
    func dismissOnboarding() {
        onboardingViewController?.dismiss(animated: true, completion: nil)
    }
}

// MARK: - TTTAttributedLabelDelegate

extension LoginViewController: TTTAttributedLabelDelegate {
    
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        if let termsURLString = Application.remoteConfig.configValue(forKey: Constants.App.RemoteConfig.Keys.termsURL).stringValue,
            url.absoluteString == termsURLString {
            openPage(title: termsText, url: url)
        } else {
            if let privacyURLString = Application.remoteConfig.configValue(forKey: Constants.App.RemoteConfig.Keys.privacyURL).stringValue,
                url.absoluteString == privacyURLString {
                openPage(title: privacyText, url: url)
            }
        }
    }
    
    func openPage(title: String, url: URL?) {
        let navigationController = UINavigationController()
        if let aboutWebViewController = R.storyboard.main.aboutWebViewController() {
            aboutWebViewController.url = url
            aboutWebViewController.navigationItem.title = title
            navigationController.pushViewController(aboutWebViewController, animated: false)
            self.present(navigationController, animated: true, completion: nil)
        }
    }
    
}

// MARK: BWWalkthroughViewControllerDelegate

extension LoginViewController: BWWalkthroughViewControllerDelegate {
    func walkthroughPageDidChange(_ pageNumber: Int) {
        let parameters = ["slide_name": slideNames[pageNumber]]
        Analytics.Log(event: "Onboarding_view_slide", with: parameters)
    }
}
