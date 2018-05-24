//
//  UserDetailsView.swift
//  Woojo
//
//  Created by Edouard Goossens on 21/05/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import ImageSlideshow
import SDWebImage

class UserDetailsView<T: User> : UIView {
    var view: UIView!
    
    @IBOutlet weak var pictureView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var nameAgeLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var occupationLabel: UILabel!
    
    @IBOutlet weak var carouselView: ImageSlideshow!
    
    @IBOutlet weak var eventsView: UIView!
    @IBOutlet weak var eventsHeaderLabel: UILabel!
    @IBOutlet weak var eventsTableView: UITableView!
    
    @IBOutlet weak var descriptionView: UIView!
    @IBOutlet weak var descriptionHeaderLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    
    @IBOutlet weak var friendsView: UIView!
    @IBOutlet weak var friendsHeaderLabel: UILabel!
    @IBOutlet weak var friendsCollectionView: UICollectionView!
    
    @IBOutlet weak var pageLikesView: UIView!
    @IBOutlet weak var pageLikesHeaderLabel: UILabel!
    @IBOutlet weak var pageLikesCollectionView: UICollectionView!
    
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var pictureHeightConstraint: NSLayoutConstraint!
    
    private var gradientLayer: CAGradientLayer?
    private let disposeBag = DisposeBag()
    private var isPictureExpanded = false
    
    //private var uid: String
    //private var userType: T.Type
    private var viewModel: UserDetailsViewModel<T>
    
    init(viewModel: UserDetailsViewModel<T>) {
        //self.uid = uid
        //self.userType = userType
        self.viewModel = viewModel
        super.init(frame: CGRect.zero)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    func xibSetup() {
        view = R.nib.userDetailsView().instantiate(withOwner: self, options: nil)[0] as! UIView
        view.frame = bounds
        view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        
        setupUI()
        bindViewModel()
        addSubview(view)
    }
    
    private func setupUI() {
        gradientLayer = CAGradientLayer()
        gradientLayer!.frame = carouselView.bounds
        gradientLayer!.locations = [0, 0.6, 0.8, 1.0]
        gradientLayer!.colors = [UIColor.black.withAlphaComponent(0.0).cgColor, UIColor.black.withAlphaComponent(0.0).cgColor, UIColor.black.withAlphaComponent(0.8).cgColor, UIColor.black.cgColor]
        carouselView.layer.addSublayer(gradientLayer!)
        
        carouselView.bringSubview(toFront: carouselView.pageControl)
        carouselView.pageControlPosition = .custom(padding: 16.0)
        
        eventsTableView.register(R.nib.userDetailsCommonEventTableViewCell)
        friendsCollectionView.register(R.nib.userCommonFriendCollectionViewCell)
        pageLikesCollectionView.register(R.nib.userCommonItemCollectionViewCell)
    }
    
    private func bindViewModel() {
        viewModel.nameAge.drive(nameAgeLabel.rx.text).disposed(by: disposeBag)
        
        viewModel.city.drive(cityLabel.rx.text).disposed(by: disposeBag)
        viewModel.city.map { $0.isNullOrEmpty }.drive(cityLabel.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.occupation.drive(occupationLabel.rx.text).disposed(by: disposeBag)
        viewModel.occupation.map { $0.isNullOrEmpty }.drive(occupationLabel.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.pictures
            .map { $0.map { SDWebImageFirebaseSource(storageReference: $0.value) } }
            .drive(onNext: { self.carouselView.setImageInputs($0) })
            .disposed(by: disposeBag)
        
        viewModel.firstName
            .map { R.string.localizable.peopleDetailsAbout($0 ?? "") }
            .drive(descriptionHeaderLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.description.drive(descriptionTextView.rx.text).disposed(by: disposeBag)
        viewModel.description.map { $0.isNullOrEmpty }.drive(descriptionView.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.events.drive(onNext: { events in
            DispatchQueue.main.async {
                self.tableViewHeightConstraint.constant = self.eventsTableView.contentSize.height
            }
        }).disposed(by: disposeBag)
        viewModel.events.map { R.string.plurals.peopleDetailsCommonEvents(eventCount: $0.count) }.drive(eventsHeaderLabel.rx.text).disposed(by: disposeBag)
        viewModel.events.map { $0.count == 0 }.drive(eventsView.rx.isHidden).disposed(by: disposeBag)
        viewModel.events
            .asObservable()
            .bind(to: eventsTableView.rx.items(cellIdentifier: R.reuseIdentifier.detailsCommonEventCell.identifier, cellType: UserDetailsCommonEventTableViewCell.self)) { _, event, cell in cell.event = event }
            .disposed(by: disposeBag)
        
        viewModel.friends.map { R.string.plurals.peopleDetailsCommonFriends(friendCount: $0.count) }.drive(friendsHeaderLabel.rx.text).disposed(by: disposeBag)
        viewModel.friends.map { $0.count == 0 }.drive(friendsView.rx.isHidden).disposed(by: disposeBag)
        viewModel.friends
            .asObservable()
            .bind(to: friendsCollectionView.rx.items(cellIdentifier: R.reuseIdentifier.commonFriendCell.identifier, cellType: UserCommonFriendCollectionViewCell.self)) { _, user, cell in cell.user = user }
            .disposed(by: disposeBag)
        
        viewModel.pageLikes.map { R.string.plurals.peopleDetailsCommonInterests(interestCount: $0.count) }.drive(pageLikesHeaderLabel.rx.text).disposed(by: disposeBag)
        viewModel.pageLikes.map { $0.count == 0 }.drive(pageLikesView.rx.isHidden).disposed(by: disposeBag)
        viewModel.pageLikes
            .asObservable()
            .bind(to: pageLikesCollectionView.rx.items(cellIdentifier: R.reuseIdentifier.commonItemCell.identifier, cellType: UserCommonItemCollectionViewCell.self)) { _, item, cell in cell.item = item }
            .disposed(by: disposeBag)
        
    }
    
    @IBAction func tappedOnPicture() {
        isPictureExpanded ? collapsePicture() : expandPicture()
    }
    
    private func expandPicture() {
        UIView.animate(withDuration: 0.3, animations: {
            self.pictureHeightConstraint.constant = UIScreen.main.bounds.height
            self.view.layoutIfNeeded()
        })
        isPictureExpanded = true
    }
    
    private func collapsePicture() {
        UIView.animate(withDuration: 0.3, animations: {
            self.pictureHeightConstraint.constant = 300
            self.view.layoutIfNeeded()
        })
        isPictureExpanded = false
    }
    
    private func showActions() {
        //delegate.show
    }
}
