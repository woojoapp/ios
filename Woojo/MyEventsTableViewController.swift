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
    
    var events: [Event]?

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 100
        
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(loadFacebookEvents), for: UIControlEvents.valueChanged)
        
        loadFacebookEvents()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
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
        if let events = events {
            return events.count
        } else {
            return 0
        }
    }
    
    func loadFacebookEvents() {
        CurrentUser.getEventsFromFacebook { events in
            self.events = events
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fbEventCell", for: indexPath)

        if let event = self.events?[indexPath.row] {
            cell.textLabel?.text = event.name
            var placeString = "Unknown location"
            if let place = event.place, let placeName = place.name {
                placeString = placeName
            }
            if let location = event.place?.location, let city = location.city {
                if placeString != "Unknown location" {
                    placeString = "\(placeString) (\(city))"
                } else {
                    placeString = city
                }
            }
            //cell.accessoryType
            cell.detailTextLabel?.text = placeString
            if let pictureURL = event.pictureURL {
                cell.imageView?.sd_setImage(with: pictureURL, placeholderImage: #imageLiteral(resourceName: "placeholder_40x40"))
            } else {
                cell.imageView?.image = #imageLiteral(resourceName: "placeholder_40x40")
            }
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
