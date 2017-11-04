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
    var user: User?
    var commonEventInfos: [User.CommonEventInfo] = []
    var imageSources: [ImageSource] = []
    var initiallyShowDescription = false
    
    var candidatesViewController: CandidatesViewController?
    
    //@IBOutlet var imageView: UIImageView!
    @IBOutlet var detailsView: UIView!
    @IBOutlet var eventImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var centerNameLabel: UILabel!
    @IBOutlet var firstCommonEventLabel: UILabel!
    @IBOutlet var additionalCommonEventsLabel: UILabel!
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
    
    func load(completion: (() -> ())? = nil) {
        detailsView.backgroundColor = UIColor(cgColor: CGColor(colorLiteralRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.7))
        
        carouselView.backgroundColor = UIColor.white
        carouselView.circular = false
        carouselView.contentScaleMode = .scaleAspectFill
        carouselView.draggingEnabled = false
        carouselView.pageControlPosition = .hidden
        carouselView.scrollView.bounces = false
        //carouselView.layer.borderWidth = 1.0
        //carouselView.layer.borderColor = .wh
        
        previousPhotoImageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: self.previousPhotoButton.frame.width, height: self.previousPhotoButton.frame.height))
        previousPhotoImageView?.contentMode = .scaleAspectFill
        previousPhotoImageView?.clipsToBounds = true
        previousPhotoImageView?.layer.masksToBounds = true
        previousPhotoImageView?.layer.cornerRadius = self.previousPhotoButton.frame.width / 2.0
        previousPhotoImageView?.layer.borderWidth = 1.0
        previousPhotoImageView?.layer.borderColor = UIColor.white.cgColor
        self.previousPhotoButton.addSubview(previousPhotoImageView!)
        
        nextPhotoImageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: self.nextPhotoButton.frame.width, height: self.nextPhotoButton.frame.height))
        nextPhotoImageView?.contentMode = .scaleAspectFill
        nextPhotoImageView?.clipsToBounds = true
        nextPhotoImageView?.layer.masksToBounds = true
        nextPhotoImageView?.layer.cornerRadius = self.nextPhotoButton.frame.width / 2.0
        nextPhotoImageView?.layer.borderWidth = 1.0
        nextPhotoImageView?.layer.borderColor = UIColor.white.cgColor
        self.nextPhotoButton.addSubview(nextPhotoImageView!)
        
        nameLabel.textAlignment = .center
        firstCommonEventLabel.textAlignment = .center
        additionalCommonEventsLabel.textAlignment = .center
        
        tableView.register(UINib(nibName: "CandidateCommonEventTableViewCell", bundle: nil), forCellReuseIdentifier: "commonEventCell")
        tableView.register(UINib(nibName: "CandidateDescriptionTableViewCell", bundle: nil), forCellReuseIdentifier: "descriptionCell")
        tableView.delegate = self
        tableView.dataSource = self
        
        if let user = user {
            nameLabel.text = user.profile.displaySummary
            centerNameLabel.text = user.profile.displaySummary
            firstCommonEventLabel.text = commonEventInfos.first?.name
            
            if commonEventInfos.count > 0 {
                Event.get(for: commonEventInfos[0].id, completion: { (event) in
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
            if commonEventInfos.count > 1 {
                let eventString = (commonEventInfos.count > 2) ? "events" : "event"
                additionalCommonEventsLabel.text = "+\(commonEventInfos.count - 1) more common \(eventString)"
            } else {
                additionalCommonEventsLabel.text = ""
            }
            
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
                    if self.initiallyShowDescription {
                        self.setDescriptionShownState()
                        self.isShowingDescription = true
                    }
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
                Analytics.Log(event: Constants.Analytics.Events.CandidateDetailsPhotoChanged.name, with: [Constants.Analytics.Events.CandidateDetailsPhotoChanged.Parameters.uid: user.uid])
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
    
    func setDescriptionShownState() {
        let baseUnit = self.view.frame.width / 2.5
        self.carouselView.frame = CGRect(x: self.view.frame.width / 2.0 - baseUnit / 2.0, y: baseUnit / 4.0, width: baseUnit, height: baseUnit)
        self.carouselView.layer.cornerRadius = self.carouselView.frame.width / 2.0
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
    }
    
    func showDescription() {
        UIView.animate(withDuration: 0.25, animations: {
            self.setDescriptionShownState()
        }, completion: { finished in
            self.isShowingDescription = finished
        })
    }
    
    func setDecriptionHiddenState() {
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
    }
    
    func hideDescription() {
        UIView.animate(withDuration: 0.25, animations: {
            self.setDecriptionHiddenState()
        }, completion: { finished in
            self.isShowingDescription = !finished
        })
    }
    
    func toggleDescription() {
        if isShowingDescription {
            hideDescription()
        } else {
            showDescription()
        }
    }
    
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
                return "Common Events"
            } else if section == 1 {
                return "About \(name)"
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
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return commonEventInfos.count
        } else if section == 1 {
            return 1
        } else {
            return 0
        }
    }
    
    /*func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            
        }
    }*/
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "commonEventCell", for: indexPath) as! CandidateCommonEventTableViewCell
            let eventId = commonEventInfos[indexPath.row].id
            Event.get(for: eventId, completion: { (event) in
                if let event = event,
                    let pictureURL = event.pictureURL {
                    cell.eventImageView.layer.cornerRadius = 8.0
                    cell.eventImageView.layer.masksToBounds = true
                    cell.eventImageView.sd_setImage(with: pictureURL, placeholderImage: #imageLiteral(resourceName: "placeholder_100x100"))
                }
            })
            cell.eventTextLabel.text = commonEventInfos[indexPath.row].displayString
            return cell
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "descriptionCell", for: indexPath)
            if let user = user {
                cell.textLabel?.text = user.profile.description.value
            }
            return cell
        }
        return tableView.dequeueReusableCell(withIdentifier: "commonEventCell", for: indexPath)
    }
}