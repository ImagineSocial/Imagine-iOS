//
//  FactCollectionViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 21.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

private let reuseIdentifier = "FactCell"

class FactCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var facts = [Fact]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        getFacts()
        
    }

   
    func getFacts() {
        DataHelper().getData(get: "facts") { (facts) in
            self.facts = facts as! [Fact]
            self.collectionView.reloadData()
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return facts.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? FactCell {
            
            let fact = facts[indexPath.row]
            cell.factCellLabel.text = fact.title
            
            if let url = URL(string: fact.imageURL) {
                cell.factCellImageView.sd_setImage(with: url, completed: nil)
                cell.factCellImageView.contentMode = .scaleAspectFill
                cell.factCellImageView.alpha = 0.9
            }
            
            
            return cell
        }
    
        return UICollectionViewCell()
    }

    // MARK: UICollectionViewDelegate

    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        
        let newSize = CGSize(width: (collectionView.frame.size.width/2)-3, height: (collectionView.frame.size.width/2)-3)
        
        return newSize
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "goToArguments", sender: facts[indexPath.row])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToArguments" {
            if let fact = sender as? Fact {
                if let argumentVC = segue.destination as? FactParentContainerViewController {
                    argumentVC.fact = fact
                }
                
            }
        }
    }

}

class FactCell:UICollectionViewCell {
    @IBOutlet weak var factCellLabel: UILabel!
    @IBOutlet weak var factCellImageView: UIImageView!
}
