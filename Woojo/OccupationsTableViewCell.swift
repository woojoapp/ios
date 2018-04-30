//
//  OccupationsTableViewCell.swift
//  Woojo
//
//  Created by Edouard Goossens on 27/03/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import UIKit

class OccupationsTableViewCell: UITableViewCell, UITableViewDataSource, UITableViewDelegate {
    
    //@IBOutlet var tableView: UITableView!
    @IBOutlet var textView: UITextView!
    var occupations: [String]? {
        didSet {
            //tableView.reloadData()
        }
    }
    var selectedOccupation: String? {
        didSet {
            //tableView.reloadData()
            textView.text = oldValue
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupDataSources()
    }
    
    func setupDataSources() {
        /* tableView.register(UINib(nibName: "OccupationTableViewCell", bundle: nil), forCellReuseIdentifier: "occupationCell")
        tableView.dataSource = self
        tableView.delegate = self */
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(40)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return occupations?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let occupation = occupations?[indexPath.row] {
            User.current.value?.profile.setOccupation(occupation: occupation)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "occupationCell", for: indexPath) as! OccupationTableViewCell
        if let occupation = occupations?[indexPath.row] {
            cell.textLabel?.text = occupation
            if let selectedOccupation = selectedOccupation,
                occupation == selectedOccupation {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        }
        return cell
    }
    
}
