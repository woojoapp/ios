//
//  USerCommonFriendsTableViewCell.swift
//  Woojo
//
//  Created by Edouard Goossens on 07/11/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import UIKit

class UserCommonItemsTableViewCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var items: [CommonItem] = []

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        collectionView.register(UINib(nibName: "UserCommonItemCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "commonItemCell")
        
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    // MARK: UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("CELLFORITEMAT", items[indexPath.row].name)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "commonItemCell", for: indexPath) as! UserCommonItemCollectionViewCell
        cell.item = items[indexPath.row]
        return cell
    }
    
}
