//
//  EventDetailsViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 14/11/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import UIKit
import RxSwift

class EventDetailsViewController: UITableViewController {
    var event: Event!
    private var matches: [Match] = []
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        observeEvent()
    }
    
    private func observeEvent() {
        if let eventId = event.id {
            EventRepository.shared.get(eventId: eventId).subscribe(onNext: { event in
                if let event = event {
                    self.event = event
                    self.tableView.reloadData()
                }
            }, onError: { _ in
                
            }).disposed(by: disposeBag)
        }
    }
    
    private func observeMatches() {
        /* if let eventId = event.id {
         TODO: Observe Matches
        } */
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            if matches.count > 0 {
                return 1
            } else {
                return 0
            }
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return nil
        } else if section == 1 {
            if matches.count == 0 {
                return nil
            } else {
                let people = (matches.count > 1) ? NSLocalizedString("people", comment: "") : NSLocalizedString("person", comment: "")
                return String(format: NSLocalizedString("You matched with %d %@ in this event", comment: ""), matches.count, people)
            }
        } else if section == 2 {
            if event.description == nil {
                return nil
            } else {
                if let name = event.name {
                    return String(format: NSLocalizedString("About %@", comment: ""), name)
                }
                return nil
            }
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let view = view as? UITableViewHeaderFooterView {
            view.textLabel?.font = .boldSystemFont(ofSize: 13.0)
        }
    }
    
    private func getPlaceString(place: Place?) -> String {
        var placeString = Constants.Place.defaultDisplayString
        if let placeName = place?.name {
            placeString = placeName
        }
        if let location = place?.location, let city = location.city {
            if placeString != Constants.Place.defaultDisplayString && placeString != city {
                placeString = "\(placeString) (\(city))"
            } else {
                placeString = city
            }
        }
        return placeString
    }
    
    private func getTimeString(start: Date, end: Date?) -> String {
        let humanDateFormatter = DateFormatter()
        humanDateFormatter.calendar = Calendar(identifier: .iso8601)
        humanDateFormatter.dateFormat = "dd MMM yyyy, HH:mm"
        var timesString = humanDateFormatter.string(from: start)
        if let end = end {
            timesString = "\(timesString) - \(humanDateFormatter.string(from: end))"
        }
        return timesString
    }
    
    private func getRsvpString(event: Event?) -> String {
        var rsvpInfo: [String] = []
        if let attendingCount = event?.attendingCount {
            rsvpInfo.append(String(format: NSLocalizedString("%d going", comment: ""), attendingCount))
        }
        if let interestedCount = event?.interestedCount {
            rsvpInfo.append(String(format: NSLocalizedString("%d maybe", comment: ""), interestedCount))
        }
        if let noReplyCount = event?.noReplyCount {
            rsvpInfo.append(String(format: NSLocalizedString("%d invited", comment: ""), noReplyCount))
        }
        return rsvpInfo.joined(separator: ", ")
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "detailsCell", for: indexPath) as! EventDetailsTableViewCell
            cell.nameLabel.text = event.name
            cell.placeLabel.text = getPlaceString(place: event.place)
            if let start = event.start {
                cell.timesLabel.text = getTimeString(start: start, end: event.end)
            }
            if event.type != "plan" { cell.rsvpLabel.text = getRsvpString(event: event) }
            else { cell.rsvpLabel.isHidden = true }
            cell.coverImageView.contentMode = .scaleAspectFill
            if let urlString = event.coverURL,
                let coverURL = URL(string: urlString) {
                cell.coverImageView.sd_setImage(with: coverURL, placeholderImage: #imageLiteral(resourceName: "placeholder_100x100"))
                cell.eventImageView.sd_setImage(with: coverURL, placeholderImage: #imageLiteral(resourceName: "placeholder_100x100"))
            }
            cell.eventImageView.layer.cornerRadius = 12.0
            cell.eventImageView.layer.masksToBounds = true
            cell.eventImageView.layer.borderColor = UIColor.white.cgColor
            cell.eventImageView.layer.borderWidth = 2.0
            cell.eventImageView.contentMode = .scaleAspectFill
            
            return cell
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "matchesCell", for: indexPath) as! EventMatchesTableViewCell
            cell.matches = matches
            cell.collectionView.dataSource = cell
            cell.collectionView.delegate = cell
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
