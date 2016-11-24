//
//  EventViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 04/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import Koloda

class CandidatesViewController: UIViewController, KolodaViewDelegate, KolodaViewDataSource, CandidatesDelegate {
    
    @IBOutlet weak var kolodaView: KolodaView!
    
    @IBAction func likePressed(_ sender: Any) {
        kolodaView?.swipe(.right)
    }
    
    @IBAction func passPressed(_ sender: Any) {
        kolodaView?.swipe(.left)
    }
    
    var shouldApplyAppearAnimation = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //CurrentUser.candidatesDelegate = self
        
        kolodaView.dataSource = self
        kolodaView.delegate = self
        
        self.shouldApplyAppearAnimation = false
        
        print("Candidates \(User.current?.candidates)")
        
        let settingsItem = UIBarButtonItem()
        let settingsButton = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        settingsButton.layer.cornerRadius = settingsButton.frame.width / 2
        settingsButton.layer.masksToBounds = true
        User.current?.profile.generatePhotoDownloadURL { url, error in
            if let url = url {
                settingsButton.sd_setImage(with: url, for: .normal)
            }
        }
        settingsButton.addTarget(self, action: #selector(showSettings), for: .touchUpInside)
        settingsItem.customView = settingsButton
        self.navigationItem.setRightBarButton(settingsItem, animated: true)
    }
    
    func showSettings(sender : Any?) {
        let settingsController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "settingsNavigation")
        self.present(settingsController, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func didUpdateCandidates() {
        kolodaView.reloadData()
    }
    
    // MARK: - KolodaViewDelegate
    
    func koloda(_ koloda: KolodaView, didSwipeCardAt index: Int, in direction: SwipeResultDirection) {
        print("Swiped at \(index) out of \(User.current?.candidates.count)")
        switch direction {
        case .left:
            User.current?.candidates[index].pass { error, ref in
                if let error = error {
                    print("Failed to pass candidate: \(error)")
                } else {
                    //self.kolodaView.resetCurrentCardIndex()
                }
            }
            //CurrentUser.candidates[index] = Candidate()
            print(index..<index)
            User.current?.candidates.remove(at: index)
            print(kolodaView.countOfCards, kolodaView.dataSource?.kolodaNumberOfCards(kolodaView))
            kolodaView.removeCardInIndexRange(index..<index, animated: false)
            print(kolodaView.countOfCards, kolodaView.dataSource?.kolodaNumberOfCards(kolodaView))
            kolodaView.currentCardIndex = 0
        case .right:
            User.current?.candidates[index].like { error, ref in
                if let error = error {
                    print("Failed to like candidate: \(error)")
                } else {
                    //self.kolodaView.resetCurrentCardIndex()
                }
            }
            //CurrentUser.candidates[index] = Candidate()
            User.current?.candidates.remove(at: index)
            kolodaView.removeCardInIndexRange(index..<index, animated: false)
            kolodaView.currentCardIndex = 0
        default:
            break
        }
        //self.kolodaView.resetCurrentCardIndex()
    }
    
    func kolodaShouldApplyAppearAnimation(_ koloda: KolodaView) -> Bool {
        return self.shouldApplyAppearAnimation
    }
    
    func kolodaDidRunOutOfCards(koloda: KolodaView) {
        
    }
    
    func koloda(koloda: KolodaView, didSelectCardAtIndex index: Int) {
        
    }
    
    // MARK: - KolodaViewDataSource
    
    func kolodaNumberOfCards(_ koloda:KolodaView) -> Int {
        return User.current!.candidates.count
    }
    
    func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {
        print("Asked for view for card \(index)")
        print("\(User.current?.candidates.count) candidates")
        let imageView = UIImageView()
        DispatchQueue.global(qos: .userInitiated).async {
            User.current?.candidates[index].profile?.generatePhotoDownloadURL { url, error in
                if let url = url {
                    do {
                        let image = UIImage(data: try Data(contentsOf: url))
                        DispatchQueue.main.async {
                            imageView.image = image
                        }
                    } catch {
                        print("Failed to get candidate image from URL: \(error.localizedDescription)")
                    }
                }
            }
        }
        return imageView
    }
    
    func koloda(koloda: KolodaView, viewForCardOverlayAtIndex index: Int) -> OverlayView? {
        return Bundle.main.loadNibNamed("OverlayView", owner: self, options: nil)?[0] as? OverlayView
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
