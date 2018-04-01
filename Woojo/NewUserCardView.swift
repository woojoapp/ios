//
//  NewUserCardView.swift
//  Woojo
//
//  Created by Edouard Goossens on 26/03/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import UIKit
import ImageSlideshow

class NewUserCardView: UIView {
    var view: UIView!
    var user: User?
    var commonEventInfos: [User.CommonEventInfo] = []
    var commonFriends: [Friend] = []
    var commonPageLikes: [PageLike] = []
    var imageSources: [ImageSource] = []
    
    var maxCommonEventsCount = 2
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var occupationLabel: UILabel!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var carouselView: ImageSlideshow!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var locationView: UIView!
    @IBOutlet weak var occupationView: UIView!
    
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func loadViewFromNib() -> UIView {
        return UINib(nibName: "NewUserCardView", bundle: Bundle.main).instantiate(withOwner: self, options: nil).first as! UIView
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
        backgroundImageView.contentMode = .scaleAspectFill
        carouselView.contentScaleMode = .scaleAspectFill
        
        tableView.register(UINib(nibName: "UserCommonEventTableViewCell", bundle: nil), forCellReuseIdentifier: "commonEventCell")
        tableView.register(UINib(nibName: "UserExtraCommonEventsTableViewCell", bundle: nil), forCellReuseIdentifier: "extraCommonEventsCell")
        tableView.delegate = self
        tableView.dataSource = self
        
        if UIScreen.main.bounds.height < 650 {
            maxCommonEventsCount = 1
        }
        
        if let user = user {
            nameLabel.text = user.profile.displaySummary
            nameLabel.layer.shadowColor = UIColor.black.cgColor
            nameLabel.layer.shadowRadius = 2.0
            nameLabel.layer.shadowOpacity = 1.0
            nameLabel.layer.shadowOffset = CGSize(width: 2, height: 2)
            nameLabel.layer.masksToBounds = false
            
            if let city = user.profile.location?.city {
                locationLabel.text = user.profile.location?.city
                locationLabel.layer.shadowColor = UIColor.black.cgColor
                locationLabel.layer.shadowRadius = 2.0
                locationLabel.layer.shadowOpacity = 1.0
                locationLabel.layer.shadowOffset = CGSize(width: 2, height: 2)
                locationLabel.layer.masksToBounds = false
            } else {
                locationView.isHidden = true
                locationView.addConstraint(NSLayoutConstraint(item: locationView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0.0))
            }
            
            if !user.profile.occupation.value.isEmpty {
                occupationLabel.text = user.profile.occupation.value
                occupationLabel.layer.shadowColor = UIColor.black.cgColor
                occupationLabel.layer.shadowRadius = 2.0
                occupationLabel.layer.shadowOpacity = 1.0
                occupationLabel.layer.shadowOffset = CGSize(width: 2, height: 2)
                occupationLabel.layer.masksToBounds = false
            } else {
                occupationView.isHidden = true
                occupationView.addConstraint(NSLayoutConstraint(item: occupationView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0.0))
            }
            
            carouselView.layer.borderColor = UIColor.white.cgColor
            carouselView.layer.borderWidth = 2.0
            carouselView.layer.masksToBounds = true
            carouselView.layer.cornerRadius = 10
            
            let blurEffect = UIBlurEffect(style: .regular)
            let blurredEffectView = UIVisualEffectView(effect: blurEffect)
            blurredEffectView.alpha = 0.9
            blurredEffectView.frame = backgroundImageView.bounds
            view.insertSubview(blurredEffectView, aboveSubview: backgroundImageView)
            
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = backgroundImageView.bounds
            // gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.9)
            // gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
            gradientLayer.locations = [0, 0.7]
            gradientLayer.colors = [UIColor.black.withAlphaComponent(0.0).cgColor, UIColor.black.cgColor]
            blurredEffectView.layer.addSublayer(gradientLayer)
            
            func setFirstImageAndDownloadOthers(firstPhoto: User.Profile.Photo) {
                if let firstImage = firstPhoto.images[.full] {
                    self.backgroundImageView.image = firstImage
                    self.imageSources.append(ImageSource(image: firstImage))
                    self.carouselView.setImageInputs(self.imageSources)
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
                    /* self.setPhotoButtons(index: 0)
                    if self.initiallyShowDescription {
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
            /* if commonEventInfos.count > 0 {
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
                let eventString = (commonEventInfos.count > 2) ? NSLocalizedString("events", comment: "") : NSLocalizedString("event", comment: "")
                additionalCommonEventsLabel.text = String(format: NSLocalizedString("+%d more common %@", comment: ""), commonEventInfos.count - 1, eventString)
            } else {
                additionalCommonEventsLabel.text = ""
            } */
        }
        addSubview(view)
        DispatchQueue.main.async {
            self.tableViewHeightConstraint.constant = self.tableView.contentSize.height
        }
    }
}

extension NewUserCardView: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if commonEventInfos.count > maxCommonEventsCount {
            return 2
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return min(maxCommonEventsCount, commonEventInfos.count)
        } else if section == 1 {
            return 1
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "commonEventCell", for: indexPath) as! UserCommonEventTableViewCell
            let eventId = commonEventInfos[indexPath.row].id
            Event.get(for: eventId, completion: { (event) in
                if let event = event,
                    let pictureURL = event.pictureURL {
                    cell.eventImageView.layer.cornerRadius = 8.0
                    cell.eventImageView.layer.masksToBounds = true
                    cell.eventImageView.sd_setImage(with: pictureURL, placeholderImage: #imageLiteral(resourceName: "placeholder_100x100"))
                }
            })
            cell.eventTextLabel.text = commonEventInfos[indexPath.row].name
            return cell
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "extraCommonEventsCell", for: indexPath) as! UserExtraCommonEventsTableViewCell
            cell.eventExtraNumberLabel.text = "+\(String(commonEventInfos.count - maxCommonEventsCount))"
            cell.eventTextLabel.text = "Extra common event"
            return cell
        }
        return tableView.dequeueReusableCell(withIdentifier: "commonEventCell", for: indexPath)
    }
}

extension NewUserCardView: UITableViewDelegate {
    
}
