//
//  EventDetailsViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 14/11/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import UIKit

class EventDetailsViewController: UITableViewController {
    var event: Event?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            if let event = event {
                if event.matches.count > 0 {
                    return 1
                } else {
                    return 0
                }
            } else {
                return 0
            }
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let event = event {
            if section == 0 {
                return nil
            } else if section == 1 {
                if event.matches.count == 0 {
                    return nil
                } else {
                    return "You have \(String(event.matches.count)) \((event.matches.count > 1) ? "matches" : "match") in this event"
                }
            } else if section == 2 {
                if event.description == nil {
                    return nil
                } else {
                    return "About \(event.name)"
                }
            }
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let view = view as? UITableViewHeaderFooterView {
            view.textLabel?.font = .boldSystemFont(ofSize: 13.0)
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "detailsCell", for: indexPath) as! EventDetailsTableViewCell
            cell.nameLabel.text = event?.name
            cell.placeLabel.text = event?.place?.displayString
            cell.timesLabel.text = event?.timesString
            cell.rsvpLabel.text = event?.rsvpString
            if let coverURL = event?.coverURL {
                cell.coverImageView.contentMode = .scaleAspectFill
                cell.coverImageView.sd_setImage(with: coverURL, placeholderImage: #imageLiteral(resourceName: "placeholder_100x100"))
            }
            if let eventImageURL = event?.pictureURL {
                cell.eventImageView.layer.cornerRadius = 12.0
                cell.eventImageView.layer.masksToBounds = true
                cell.eventImageView.layer.borderColor = UIColor.white.cgColor
                cell.eventImageView.layer.borderWidth = 2.0
                cell.eventImageView.contentMode = .scaleAspectFill
                cell.eventImageView.sd_setImage(with: eventImageURL, placeholderImage: #imageLiteral(resourceName: "placeholder_100x100"))
            }
            return cell
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "matchesCell", for: indexPath) as! EventMatchesTableViewCell
            if let event = event {
                cell.matches = event.matches
                cell.collectionView.dataSource = cell
                cell.collectionView.delegate = cell
            }
            cell.collectionView.reloadData()
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "descriptionCell", for: indexPath) as! EventDescriptionTableViewCell
            cell.descriptionTextView.textContainerInset = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
            cell.descriptionTextView.text = event?.description
            return cell
        }
    }
}
