//
//  OnboardingPostAboutViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 19/03/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import UIKit
import RxSwift

class OnboardingPostAboutViewController: OnboardingPostBaseViewController {
    
    @IBOutlet weak var tapGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet weak var bioTextView: UITextView!
    @IBOutlet weak var charactersLeftLabel: UILabel!
    
    fileprivate let bioTextViewPlaceholderText = NSLocalizedString("Tell other members why...", comment: "")
    fileprivate var previousBio: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBioTextView()
        User.current.asObservable()
            .flatMap { user -> Observable<String> in                
                if let currentUser = user {
                    return currentUser.profile.description.asObservable()
                } else {
                    return Variable(self.bioTextViewPlaceholderText).asObservable()
                }
            }
            .map{ text -> String in
                if(text == "") {
                    self.bioTextView.textColor = UIColor.lightGray
                    return self.bioTextViewPlaceholderText
                } else {
                    self.bioTextView.textColor = UIColor.black
                    return text
                }
            }
            .bind(to: bioTextView.rx.text)
            .disposed(by: disposeBag)
    }
    
    func setupBioTextView() {
        bioTextView.delegate = self
        tapGestureRecognizer.addTarget(self, action: #selector(tap))
        tapGestureRecognizer.cancelsTouchesInView = false
        bioTextView.layer.cornerRadius = 5
        bioTextView.clipsToBounds = true
        bioTextView.rx.text
            .map{ $0?.count }
            .subscribe(onNext: { count in
                self.setBioFooter(count: count)
            }).disposed(by: disposeBag)
    }
    
    @IBAction func tap(gesture: UITapGestureRecognizer) {
        bioTextView.resignFirstResponder()
    }
    
    func setBioFooter(count: Int?) {
        if let count = count {
            let s = count != 249 ? NSLocalizedString("characters", comment: "") : NSLocalizedString("character", comment: "")
            charactersLeftLabel.text = String(format: NSLocalizedString("%d %@ left", comment: ""), max(250 - count, 0), s)
        }
    }

}

// MARK: - UITextViewDelegate

extension OnboardingPostAboutViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        previousBio = textView.text
        if bioTextView.text == bioTextViewPlaceholderText {
            bioTextView.text = ""
            bioTextView.textColor = UIColor.black
        }
        charactersLeftLabel.isHidden = false
        setBioFooter(count: bioTextView.text.count)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        let newBio = bioTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        User.current.value?.profile.setDescription(description: newBio, completion: { error in
            if error != nil {
                self.bioTextView.text = self.previousBio
            } else {
                Analytics.setUserProperties(properties: ["about_character_count": String(newBio.count)])
                Analytics.Log(event: "Onboarding_about_updated", with: ["character_count": String(newBio.count)])
            }
        })
        charactersLeftLabel.isHidden = true
        if bioTextView.text == "" {
            bioTextView.text = bioTextViewPlaceholderText
            bioTextView.textColor = UIColor.lightGray
        } else {
            bioTextView.text = newBio
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.count
        return numberOfChars <= 250 || numberOfChars < textView.text.count
    }
}
