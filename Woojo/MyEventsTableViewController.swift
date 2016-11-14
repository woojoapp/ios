//
//  MyEventsTableViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 08/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class MyEventsTableViewController: UITableViewController {
    
    var events: [[String: Any]]?

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(loadFacebookEvents), for: UIControlEvents.valueChanged)
        
        loadFacebookEvents()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        if events != nil {
            self.tableView.separatorStyle = .singleLine
            return 1
        } else {
            let messageLabel = UILabel(frame: CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
            messageLabel.text = "No events. Pull to refresh."
            messageLabel.textColor = UIColor.darkGray
            messageLabel.numberOfLines = 0
            messageLabel.textAlignment = .center
            messageLabel.sizeToFit()
            
            self.tableView.backgroundView = messageLabel
            self.tableView.separatorStyle = .none
            
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if let events = events {
            return events.count
        } else {
            return 0
        }
    }
    
    func loadFacebookEvents() {
        //(UIApplication.shared.delegate as! AppDelegate).ensureFacebookAuth()
        let fields = ["fields": "id,name"]
        let graphRequest = FBSDKGraphRequest.init(graphPath: "me/events", parameters: fields, tokenString: FBSDKAccessToken.current().tokenString, version: "v2.8", httpMethod: "GET")
        _ = graphRequest?.start() { (connection, result, error) in
            if error != nil {
                print("Error performing graph request: \(error)")
            } else if let result = result as? [String: Any] {
                self.events = result["data"] as? [[String: Any]]
                self.tableView.reloadData()
                self.tableView.refreshControl?.endRefreshing()
            }
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fbEventCell", for: indexPath)

        print("ASKED FOR CELL")
        if let event = self.events?[indexPath.row] {
            cell.textLabel?.text = event["name"] as? String
        }

        return cell
    }

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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
