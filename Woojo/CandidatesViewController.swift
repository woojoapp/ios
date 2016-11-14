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
import Koloda

class CandidatesViewController: UIViewController, KolodaViewDelegate, KolodaViewDataSource {
    
    @IBOutlet weak var kolodaView: KolodaView!
    
    @IBAction func likePressed(_ sender: Any) {
        kolodaView?.swipe(.right)
    }
    
    @IBAction func passPressed(_ sender: Any) {
        kolodaView?.swipe(.left)
    }
    
    
    var candidates: [Candidate] = []
    let ref: FIRDatabaseReference! = FIRDatabase.database().reference()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let candidatesRef = ref.child("users").child(FIRAuth.auth()!.currentUser!.uid).child("candidates")
        candidatesRef.keepSynced(true)
        candidatesRef.observe(.value, with: { (snapshot) in
            for candidateSnapshot in snapshot.children {
                if var candidate = Candidate.from(snapshot: candidateSnapshot as! FIRDataSnapshot) {
                    print(candidate)
                    candidate.getPicture { (image) in
                        candidate.picture = image
                        self.candidates.append(candidate)
                        self.kolodaView.resetCurrentCardIndex()
                        print(self.candidates)
                    }
                }
            }
            
            print("\(self.candidates.count) candidates")
            
        })
        
        kolodaView.dataSource = self
        kolodaView.delegate = self

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func showSettings(sender: UIBarButtonItem) {
        performSegue(withIdentifier: "ShowSettings", sender: sender)
    }
    
    // MARK: - KolodaViewDelegate
    
    func koloda(_ koloda: KolodaView, didSwipeCardAt index: Int, in direction: SwipeResultDirection) {
        print("Swiped \(direction.rawValue)")
        //if direction == .right { Like.on(user: candidates[index].uid, in: event!) }
        //if direction == .left { Pass.on(user: candidates[index].uid, in: event!) }
    }
    
    func kolodaDidRunOutOfCards(koloda: KolodaView) {
        
    }
    
    func koloda(koloda: KolodaView, didSelectCardAtIndex index: Int) {
        
    }
    
    // MARK: - KolodaViewDataSource
    
    func kolodaNumberOfCards(_ koloda:KolodaView) -> Int {
        return candidates.count
    }
    
    func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {
        print("Asked for view for card \(index)")
        print("\(candidates.count) candidates")
        return UIImageView(image: candidates[Int(index)].picture)
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
