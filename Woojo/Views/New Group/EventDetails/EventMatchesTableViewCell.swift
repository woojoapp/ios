//
//  EventMatchesTableViewCell.swift
//  Woojo
//
//  Created by Edouard Goossens on 14/11/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import UIKit

class EventMatchesTableViewCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var collectionView: UICollectionView!
    
    var matches: [User] = []
    
    // MARK: UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return matches.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "eventMatchCell", for: indexPath) as! EventMatchCollectionViewCell
        cell.user = matches[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 64, height: 72)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let applicationDelegate = UIApplication.shared.delegate as? Application {
            applicationDelegate.navigateToChat(otherUid: matches[indexPath.row].uid)
        }
    }
}
