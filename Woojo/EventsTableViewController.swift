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
import FirebaseDatabaseUI

class EventsTableViewController: UITableViewController {
    
    let ref: FIRDatabaseReference! = FIRDatabase.database().reference()
    var dataSource: FirebaseTableViewDataSource!
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.rowHeight = 100
        
        FIRAuth.auth()?.addStateDidChangeListener { auth, user in
            if let user = user {
                self.setDataSource(for: user.uid)
                //self.tableView.reloadData()
            }
        }
        
    }
    
    func setDataSource(for uid: String) {
        print("Setting events dataSource for \(uid)")
        
        self.dataSource = FirebaseTableViewDataSource(ref: ref.child("users").child(uid).child("events"),
                                                      modelClass: FIRDataSnapshot.self,
                                                      nibNamed: "EventsTableViewCell",
                                                      cellReuseIdentifier: "EventCell",
                                                      view: self.tableView)
        self.dataSource.populateCell { (cell: UITableViewCell, obj: NSObject) in
            let snap = obj as! FIRDataSnapshot
            let eventCell = cell as! EventsTableViewCell
            let eventRef = self.ref.child("events").child(snap.key)
            eventRef.keepSynced(true)
            eventRef.observe(.value) { (eventSnap: FIRDataSnapshot) in
                let event = Event.from(snapshot: eventSnap)!
                eventCell.populate(with: event)
            }
        }
        
        self.tableView.dataSource = self.dataSource
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
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
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
