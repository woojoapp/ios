//
//  EditCityViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 16/02/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import UIKit

class EditCityViewController: UITableViewController, UISearchBarDelegate, UISearchDisplayDelegate {
    
    //var cities = [String]()
    
    var cities = ["Paris",
    "New-York",
    "Miami",
    "Tokyo",
    "Brussels"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cities.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cityCell", for: indexPath)
        
        cell.textLabel?.text = cities[indexPath.row]
        
        return cell
    }
    
    func filterCities(searchText: String) {
        
    }
    
}
