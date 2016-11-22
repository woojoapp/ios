//
//  EventsTableViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 03/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class EventsTableViewController: UITableViewController {
    
    //var dataSource: FUITableViewDataSource!
    
    var authStateDidChangeListenerHandle: FIRAuthStateDidChangeListenerHandle?
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 100
        
        if let authStateDidChangeListenerHandle = authStateDidChangeListenerHandle {
            FIRAuth.auth()?.removeStateDidChangeListener(authStateDidChangeListenerHandle)
        }
        authStateDidChangeListenerHandle = FIRAuth.auth()?.addStateDidChangeListener { auth, user in
            if let user = user {
                self.tableView.reloadData()
                if let avatarSettingsButton = self.navigationItem.rightBarButtonItem?.customView as? UIButton {
                    CurrentUser.Profile.photoDownloadURL { url, error in
                        if let url = url {
                            avatarSettingsButton.sd_setImage(with: url, for: .normal)
                        }
                    }
                }
            }
        }
        
        let settingsItem = UIBarButtonItem()
        let settingsButton = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        settingsButton.layer.cornerRadius = settingsButton.frame.width / 2
        settingsButton.layer.masksToBounds = true
        settingsButton.addTarget(self, action: #selector(showSettings), for: .touchUpInside)
        settingsItem.customView = settingsButton
        self.navigationItem.setRightBarButton(settingsItem, animated: true)
        
    }
    
    func showSettings(sender : Any?) {
        print(CurrentUser.Activity.signUp)
        let settingsController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "settingsNavigation")
        self.present(settingsController, animated: true, completion: nil)
    }
    
    func setDataSource(for uid: String) {
        print("Setting events dataSource for \(uid)")
        /*if let ref = CurrentUser.ref {
            self.dataSource = FUITableViewDataSource(
            self.dataSource.populateCell { (cell: UITableViewCell, obj: NSObject) in
                let snap = obj as! FIRDataSnapshot
                let eventCell = cell as! EventsTableViewCell
                let eventRef = FIRDatabase.database().reference().child("events").child(snap.key)
                eventRef.keepSynced(true)
                eventRef.observe(.value) { (eventSnap: FIRDataSnapshot) in
                    let event = Event.from(snapshot: eventSnap)!
                    eventCell.populate(with: event)
                }
            }
            
            self.tableView.dataSource = self.dataSource
        }*/
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //let cell = tableView.cellForRow(at: indexPath) as! EventsTableViewCell
        //performSegue(withIdentifier: "ShowEvent", sender: cell)
    }

    /*override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        //return dataSource.numberOfSections(in: tableView)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        //return dataSource.tableView(tableView, numberOfRowsInSection: section)
    }*/

    /*override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath)
        cell.textLabel!.text = "Cocuo"
        return cell
    }*/

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

}
