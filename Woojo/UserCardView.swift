//
//  UserCardView.swift
//  Woojo
//
//  Created by Edouard Goossens on 01/12/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import ImageSlideshow
import DZNEmptyDataSet

class UserCardView: UIView, UITableViewDelegate, UITableViewDataSource {
    var view: UIView!
    var user: OtherUser?
    /* var commonEventInfos: [User.CommonEvent] = []
    var commonFriends: [Friend] = []
    var commonPageLikes: [PageLike] = [] */
    var imageSources: [ImageSource] = []
    var initiallyShowDescription = false
    
    var candidatesViewController: CandidatesViewController?
    
    //@IBOutlet var imageView: UIImageView!
    @IBOutlet var detailsView: UIView!
    @IBOutlet var eventImageView: UIImageView!
    //@IBOutlet var nameLabel: UILabel!
    @IBOutlet var centerNameLabel: UILabel!
    //@IBOutlet var firstCommonEventLabel: UILabel!
    //@IBOutlet var additionalCommonEventsLabel: UILabel!
    @IBOutlet var carouselView: ImageSlideshow!
    @IBOutlet var nextPhotoButton: UIButton!
    @IBOutlet var previousPhotoButton: UIButton!
    @IBOutlet var tableView: UITableView!
    
    var previousPhotoImageView: UIImageView?
    var nextPhotoImageView: UIImageView?
    
    var isShowingDescription = false
    
    @IBOutlet var additionalEventsBottomConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func loadViewFromNib() -> UIView {
        return UINib(nibName: "UserCardView", bundle: Bundle.main).instantiate(withOwner: self, options: nil).first as! UIView
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    func xibSetup() {
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
    }
    
    func setRoundedCornersAndShadow() {
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 24
        layer.shadowRadius = 5
        layer.shadowOpacity = 0.3
    }
    
    func addPreviousPhotoButton() {
        previousPhotoImageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: self.previousPhotoButton.frame.width, height: self.previousPhotoButton.frame.height))
        previousPhotoImageView?.contentMode = .scaleAspectFill
        previousPhotoImageView?.clipsToBounds = true
        previousPhotoImageView?.layer.masksToBounds = true
        previousPhotoImageView?.layer.cornerRadius = self.previousPhotoButton.frame.width / 2.0
        previousPhotoImageView?.layer.borderWidth = 1.0
        previousPhotoImageView?.layer.borderColor = UIColor.white.cgColor
        self.previousPhotoButton.addSubview(previousPhotoImageView!)
    }
    
    func addNextPhotoButton() {
        nextPhotoImageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: self.nextPhotoButton.frame.width, height: self.nextPhotoButton.frame.height))
        nextPhotoImageView?.contentMode = .scaleAspectFill
        nextPhotoImageView?.clipsToBounds = true
        nextPhotoImageView?.layer.masksToBounds = true
        nextPhotoImageView?.layer.cornerRadius = self.nextPhotoButton.frame.width / 2.0
        nextPhotoImageView?.layer.borderWidth = 1.0
        nextPhotoImageView?.layer.borderColor = UIColor.white.cgColor
        self.nextPhotoButton.addSubview(nextPhotoImageView!)
    }
    
    func load(completion: (() -> ())? = nil) {
        detailsView.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.7)
        
        carouselView.backgroundColor = UIColor.white
        carouselView.circular = false
        carouselView.contentScaleMode = .scaleAspectFill
        carouselView.draggingEnabled = false
        carouselView.pageControlPosition = .hidden
        carouselView.scrollView.bounces = false
        carouselView.layer.borderColor = UIColor.white.cgColor
        carouselView.layer.borderWidth = 2.0
        carouselView.layer.masksToBounds = true
        carouselView.layer.cornerRadius = 8.0
        //carouselView.layer.borderWidth = 1.0
        //carouselView.layer.borderColor = .wh
        
        addNextPhotoButton()
        addPreviousPhotoButton()
        
        // nameLabel.textAlignment = .center
        // firstCommonEventLabel.textAlignment = .center
        // additionalCommonEventsLabel.textAlignment = .center
        
        tableView.register(UINib(nibName: "UserDetailsCommonEventTableViewCell", bundle: nil), forCellReuseIdentifier: "detailsCommonEventCell")
        tableView.register(UINib(nibName: "UserDescriptionTableViewCell", bundle: nil), forCellReuseIdentifier: "descriptionCell")
        tableView.register(UINib(nibName: "UserCommonItemsTableViewCell", bundle: nil), forCellReuseIdentifier: "commonItemsCell")
        tableView.delegate = self
        tableView.dataSource = self
        
        if let user = user {
            // nameLabel.text = user.profile.displaySummary
            centerNameLabel.text = user.profile.displaySummary
            // firstCommonEventLabel.text = commonEventInfos.first?.name
            
            print("EVENTT", user.commonInfo.events.count)
            
            if user.commonInfo.events.count > 0 {
                Event.get(for: user.commonInfo.events[0].id, completion: { (event) in
                    if let event = event,
                        let url = event.coverURL {
                        do {
                            let data = try Data(contentsOf: url)
                            let image = UIImage(data: data)
                            self.eventImageView.image = image
                            self.eventImageView.contentMode = .scaleAspectFill
                            self.eventImageView.alpha = 0.25
                        } catch {
                            print("Failed to read event cover image data from url:", url)
                        }
                    }
                })
            }
            
            /* if commonEventInfos.count > 1 {
                let eventString = (commonEventInfos.count > 2) ? NSLocalizedString("events", comment: "") : NSLocalizedString("event", comment: "")
                additionalCommonEventsLabel.text = String(format: NSLocalizedString("+%d more common %@", comment: ""), commonEventInfos.count - 1, eventString)
            } else {
                additionalCommonEventsLabel.text = ""
            } */
            
            func setFirstImageAndDownloadOthers(firstPhoto: User.Profile.Photo) {
                if let firstImage = firstPhoto.images[.full] {
                    self.imageSources.append(ImageSource(image: firstImage))
                    self.carouselView.setImageInputs(self.imageSources)
                    //self.photoActivityIndicator.stopAnimating()
                }
                carouselView.pageControl.numberOfPages = user.profile.photos.value.flatMap{ $0 }.count
                carouselView.pageControl.isHidden = true
                // Download the others and append
                user.profile.downloadAllPhotos(size: .full) {
                    for photo in user.profile.photos.value {
                        if let photo = photo, let image = photo.images[.full] {
                            if photo.id == firstPhoto.id { continue }
                            else {
                                self.imageSources.append(ImageSource(image: image))
                            }
                        }
                    }
                    self.carouselView.setImageInputs(self.imageSources)
                    self.setPhotoButtons(index: 0)
                    /* if self.initiallyShowDescription {
                        self.setDescriptionShownState()
                        self.isShowingDescription = true
                    } */
                    completion?()
                }
            }
            
            // Set first photo immediately to avoid flicker
            if let firstPhoto = user.profile.photos.value[0] {
                if firstPhoto.images[.full] != nil {
                    setFirstImageAndDownloadOthers(firstPhoto: firstPhoto)
                } else {
                    firstPhoto.download(size: .full) {
                        setFirstImageAndDownloadOthers(firstPhoto: firstPhoto)
                    }
                }
                
            }
            
            carouselView.currentPageChanged = { (index) -> () in
                self.setPhotoButtons(index: index)
                /* Analytics.Log(event: Constants.Analytics.Events.CandidateDetailsPhotoChanged.name, with: [Constants.Analytics.Events.CandidateDetailsPhotoChanged.Parameters.uid: user.uid]) */
            }
        }
        addSubview(view)
    }
    
    @IBAction func previousPhoto() {
        carouselView.setCurrentPage(carouselView.currentPage - 1, animated: true)
    }
    
    @IBAction func nextPhoto() {
        carouselView.setCurrentPage(carouselView.currentPage + 1, animated: true)
    }
    
    /* func setDescriptionShownState() {
        let baseUnit = self.view.frame.width / 2.5
        self.carouselView.frame = CGRect(x: self.view.frame.width / 2.0 - baseUnit / 2.0, y: baseUnit / 4.0, width: baseUnit, height: baseUnit)
        self.carouselView.layer.cornerRadius = self.carouselView.frame.width / 2.0
        self.carouselView.setNeedsLayout()
        self.carouselView.layoutIfNeeded()
        
        self.detailsView.frame = CGRect(x: 0.0, y: 1.25 * baseUnit, width: self.view.frame.width, height: self.detailsView.frame.height)
        self.detailsView.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        
        self.centerNameLabel.isHidden = false
        self.nameLabel.isHidden = true
        self.firstCommonEventLabel.isHidden = true
        self.additionalCommonEventsLabel.isHidden = true
        
        self.tableView.frame = CGRect(x: 0.0, y: self.detailsView.frame.maxY, width: self.view.frame.width, height: self.view.frame.maxY - self.detailsView.frame.maxY)
        
        self.eventImageView.frame = CGRect(x: 0.0, y: 0.0, width: self.view.frame.width, height: self.view.frame.height - self.tableView.frame.height)
        
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
    } */
    
    /* func showDescription() {
        UIView.animate(withDuration: 0.25, animations: {
            self.setDescriptionShownState()
        }, completion: { finished in
            self.isShowingDescription = finished
        })
    } */
    
    /* func setDecriptionHiddenState() {
        self.carouselView.frame = self.view.frame
        self.carouselView.layer.cornerRadius = 0
        self.carouselView.layoutIfNeeded()
        
        self.detailsView.frame = CGRect(x: 0.0, y: self.view.frame.height - self.detailsView.frame.height, width: self.view.frame.width, height: self.detailsView.frame.height)
        self.detailsView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        
        self.centerNameLabel.isHidden = true
        self.nameLabel.isHidden = false
        self.firstCommonEventLabel.isHidden = false
        self.additionalCommonEventsLabel.isHidden = false
        
        self.tableView.frame = CGRect(x: 0.0, y: self.detailsView.frame.maxY, width: self.view.frame.width, height: self.view.frame.maxY - self.detailsView.frame.maxY)
        
        self.eventImageView.frame = CGRect(x: 0.0, y: 0.0, width: self.view.frame.width, height: self.view.frame.height - self.tableView.frame.height)
        
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
    } */
    
    /* func hideDescription() {
        UIView.animate(withDuration: 0.25, animations: {
            self.setDecriptionHiddenState()
        }, completion: { finished in
            self.isShowingDescription = !finished
        })
    } */
    
    /* @objc func toggleDescription() {
        if isShowingDescription {
            hideDescription()
        } else {
            showDescription()
        }
    } */
    
    func setPhotoButtons(index: Int) {
        if user != nil {
            if index > 0 {
                carouselView.images[index - 1].load(to: self.previousPhotoImageView!, with: { _ in })
                self.previousPhotoButton.isHidden = false
            } else {
                self.previousPhotoImageView?.image = nil
                self.previousPhotoButton.isHidden = true
            }
            if index < self.carouselView.pageControl.numberOfPages - 1 {
                carouselView.images[index + 1].load(to: self.nextPhotoImageView!, with: { _ in })
                self.nextPhotoButton.isHidden = false
            } else {
                self.nextPhotoImageView?.image = nil
                self.nextPhotoButton.isHidden = true
            }
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let user = user, let name = user.profile.displayName {
            if section == 0 {
                if user.commonInfo.events.count == 0 {
                    return nil
                } else {
                    return NSLocalizedString("Common Events", comment: "")
                }
            } else if section == 1 {
                if user.profile.description.value.count == 0 {
                    return nil
                } else {
                    return String(format: NSLocalizedString("About %@", comment: ""), name)
                }
            } else if section == 2 {
                if user.commonInfo.friends.count == 0 {
                    return nil
                } else {
                    return NSLocalizedString("Mutual Friends", comment: "")
                }
            } else if section == 3 {
                if user.commonInfo.pageLikes.count == 0 {
                    return nil
                } else {
                    return NSLocalizedString("Common Interests", comment: "")
                }
            }
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let view = view as? UITableViewHeaderFooterView {
            view.textLabel?.font = .boldSystemFont(ofSize: 13.0)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let user = user {
            if section == 0 {
                return user.commonInfo.events.count
            } else if section == 1 {
                if user.profile.description.value.count == 0 {
                    return 0
                } else {
                    return 1
                }
            } else if section == 2 {
                if user.commonInfo.friends.count == 0 {
                    return 0
                } else {
                    return 1
                }
            } else if section == 3 {
                if user.commonInfo.pageLikes.count == 0 {
                    return 0
                } else {
                    return 1
                }
            }
        }
        return 0
    }
    
    /*func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return CGFloat(commonEventInfos.count) * 32.0
        } else if indexPath.section == 1 {
            return 100.0
        } else if indexPath.section == 2 {
            return 80.0
        } else {
            return 60.0
        }
    }*/
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let user = user {
            if indexPath.section == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "detailsCommonEventCell", for: indexPath) as! UserDetailsCommonEventTableViewCell
                let eventId = user.commonInfo.events[indexPath.row].id
                Event.get(for: eventId, completion: { (event) in
                    if let event = event {
                        if let pictureURL = event.pictureURL {
                            self.setImage(pictureURL: pictureURL, cell: cell)
                        } else if let pictureURL = event.coverURL {
                            self.setImage(pictureURL: pictureURL, cell: cell)
                        } else {
                            cell.setDateVisibility(hidden: false)
                        }
                    }
                })
                cell.eventTextLabel.text = user.commonInfo.events[indexPath.row].displayString
                return cell
            } else if indexPath.section == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "descriptionCell", for: indexPath)
                cell.textLabel?.text = user.profile.description.value
                return cell
            } else if indexPath.section == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "commonItemsCell", for: indexPath) as! UserCommonItemsTableViewCell
                cell.items = user.commonInfo.friends
                cell.collectionView.reloadData()
                return cell
            } else if indexPath.section == 3 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "commonItemsCell", for: indexPath) as! UserCommonItemsTableViewCell
                cell.items = user.commonInfo.pageLikes
                cell.collectionView.reloadData()
                return cell
            }
        }
        return tableView.dequeueReusableCell(withIdentifier: "commonEventCell", for: indexPath)
    }
    
    private func setImage(pictureURL: URL, cell: UserDetailsCommonEventTableViewCell) {
        cell.eventImageView.layer.cornerRadius = 8.0
        cell.eventImageView.layer.masksToBounds = true
        cell.eventImageView.sd_setImage(with: pictureURL, placeholderImage: #imageLiteral(resourceName: "placeholder_100x100"))
        cell.setDateVisibility(hidden: true)
    }
}
