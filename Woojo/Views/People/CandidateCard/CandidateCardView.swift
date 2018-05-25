//
//  NewCandidateCardView.swift
//  Woojo
//
//  Created by Edouard Goossens on 26/03/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import UIKit
import ImageSlideshow
import RxSwift
import RxCocoa

class CandidateCardView: UIView {
    var view: UIView!
    var events: [Event] = []
    
    private let viewModel: CandidateCardViewModel
    private let disposeBag = DisposeBag()
    
    var maxCommonEventsCount = 2
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var occupationLabel: UILabel!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var locationView: UIView!
    @IBOutlet weak var occupationView: UIView!
    
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var occupationViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var locationViewHeightConstraint: NSLayoutConstraint!
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    init(viewModel: CandidateCardViewModel) {
        self.viewModel = viewModel
        super.init(frame: CGRect.zero)
        xibSetup()
    }
    
    func xibSetup() {
        view = R.nib.candidateCardView().instantiate(withOwner: self, options: nil).first as! UIView
        view.frame = bounds
        view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 24
        layer.shadowRadius = 5
        layer.shadowOpacity = 0.3
        
        setupUI()
        bindViewModel()
        addSubview(view)
    }
    
    private func setupUI() {
        backgroundImageView.contentMode = .scaleAspectFill
        profilePictureImageView.contentMode = .scaleAspectFill
        
        tableView.register(R.nib.candidateCommonEventTableViewCell)
        tableView.register(R.nib.candidateExtraCommonEventsTableViewCell)
        tableView.dataSource = self
        
        nameLabel.layer.shadowColor = UIColor.black.cgColor
        nameLabel.layer.shadowRadius = 2.0
        nameLabel.layer.shadowOpacity = 1.0
        nameLabel.layer.shadowOffset = CGSize(width: 2, height: 2)
        nameLabel.layer.masksToBounds = false
        
        locationLabel.layer.shadowColor = UIColor.black.cgColor
        locationLabel.layer.shadowRadius = 2.0
        locationLabel.layer.shadowOpacity = 1.0
        locationLabel.layer.shadowOffset = CGSize(width: 2, height: 2)
        locationLabel.layer.masksToBounds = false
        
        occupationLabel.layer.shadowColor = UIColor.black.cgColor
        occupationLabel.layer.shadowRadius = 2.0
        occupationLabel.layer.shadowOpacity = 1.0
        occupationLabel.layer.shadowOffset = CGSize(width: 2, height: 2)
        occupationLabel.layer.masksToBounds = false
        
        profilePictureImageView.layer.borderColor = UIColor.white.cgColor
        profilePictureImageView.layer.borderWidth = 2.0
        profilePictureImageView.layer.masksToBounds = true
        profilePictureImageView.layer.cornerRadius = 10
        
        let blurEffect = UIBlurEffect(style: .regular)
        let blurredEffectView = UIVisualEffectView(effect: blurEffect)
        blurredEffectView.alpha = 0.9
        blurredEffectView.frame = backgroundImageView.bounds
        view.insertSubview(blurredEffectView, aboveSubview: backgroundImageView)
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = backgroundImageView.bounds
        gradientLayer.locations = [0, 0.7]
        gradientLayer.colors = [UIColor.black.withAlphaComponent(0.0).cgColor, UIColor.black.cgColor]
        blurredEffectView.layer.addSublayer(gradientLayer)
        
        if UIScreen.main.bounds.height < 650 {
            maxCommonEventsCount = 1
        }
    }
    
    func bindViewModel() {
        viewModel.firstName
            .drive(nameLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.city
            .drive(locationLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.city
            .map { $0.isNullOrEmpty }
            .drive(locationView.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.city
            .map { $0.isNullOrEmpty }
            .map { $0 ? 0.0 : 24.0 }
            .drive(locationViewHeightConstraint.rx.constant)
            .disposed(by: disposeBag)
        
        viewModel.occupation
            .drive(occupationLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.occupation
            .map { $0.isNullOrEmpty }
            .drive(occupationView.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.occupation
            .map { $0.isNullOrEmpty }
            .map { $0 ? 0.0 : 24.0 }
            .drive(occupationViewHeightConstraint.rx.constant)
            .disposed(by: disposeBag)
        
        viewModel.profilePicture
            .drive(profilePictureImageView.rx.image)
            .disposed(by: disposeBag)
        
        viewModel.profilePicture
            .drive(backgroundImageView.rx.image)
            .disposed(by: disposeBag)
        
        viewModel.events
            .drive(onNext: { events in
                self.events = events
                self.tableView.reloadData()
                DispatchQueue.main.async {
                    self.tableViewHeightConstraint.constant = self.tableView.contentSize.height
                }
            })
            .disposed(by: disposeBag)
    }
}

extension CandidateCardView: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if events.count > maxCommonEventsCount {
            return 2
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return min(maxCommonEventsCount, events.count)
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
            let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.commonEventCell, for: indexPath)!
            let event = events[indexPath.row]
            if let urlString = event.coverURL,
                let pictureURL = URL(string: urlString) {
                cell.eventImageView.sd_setImage(with: pictureURL, placeholderImage: #imageLiteral(resourceName: "placeholder_100x100"))
                cell.setDateVisibility(hidden: true)
            } else {
                cell.setDateVisibility(hidden: false)
            }
            cell.eventTextLabel.text = event.name
            return cell
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.extraCommonEventsCell, for: indexPath)!
            cell.eventExtraNumberLabel.text = "+\(String(events.count - maxCommonEventsCount))"
            cell.eventTextLabel.text = NSLocalizedString("More common event(s)", comment: "")
            return cell
        }
        return tableView.dequeueReusableCell(withIdentifier: "commonEventCell", for: indexPath)
    }
}
