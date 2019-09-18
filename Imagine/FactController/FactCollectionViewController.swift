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
    
    let collectionViewSpacing:CGFloat = 30

    override func viewDidLoad() {
        super.viewDidLoad()
        
        getFacts()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
        
        self.view.activityStartAnimating()
    }

   
    func getFacts() {
        DataHelper().getData(get: .facts) { (facts) in
            self.facts = facts as! [Fact]
            
            let fact = Fact(addMoreDataCell: true)
            self.facts.append(fact)
            
            self.collectionView.reloadData()
            self.view.activityStopAnimating()
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
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionView.elementKindSectionHeader {  // View above CollectionView
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "collectionViewView", for: indexPath)
            
            return view
        }
        
        return UICollectionReusableView()
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let fact = facts[indexPath.row]
        
        if fact.addMoreCell {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddTopicCell", for: indexPath) as? AddTopicCell {
                
                let layer = cell.layer
                layer.cornerRadius = 4
                layer.masksToBounds = true
                layer.borderColor = Constants.imagineColor.cgColor
                layer.borderWidth = 2
                
                return cell
            }
        } else {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? FactCell {
                
                
                cell.factCellLabel.text = fact.title
                
                if let url = URL(string: fact.imageURL) {
                    cell.factCellImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: [], completed: nil)
                    cell.factCellImageView.contentMode = .scaleAspectFill
                }
                
                let gradient = CAGradientLayer()
                gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
                gradient.endPoint = CGPoint(x: 0.5, y: 0.6)
                let whiteColor = UIColor.white
                gradient.colors = [whiteColor.withAlphaComponent(0.0).cgColor, whiteColor.withAlphaComponent(0.5).cgColor, whiteColor.withAlphaComponent(0.7).cgColor]
                gradient.locations = [0.0, 0.7, 1]
                gradient.frame = cell.gradientView.bounds
                cell.gradientView.layer.mask = gradient
                
                cell.layer.cornerRadius = 4
                cell.layer.masksToBounds = true
                
                return cell
            }
        }
    
        return UICollectionViewCell()
    }

    // MARK: UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let newSize = CGSize(width: (collectionView.frame.size.width/2)-collectionViewSpacing, height: (collectionView.frame.size.width/2)-collectionViewSpacing)
        
        return newSize
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let fact = facts[indexPath.row]
        
        if fact.addMoreCell {
            performSegue(withIdentifier: "toNewArgumentSegue", sender: nil)
        } else {
            performSegue(withIdentifier: "goToArguments", sender: fact)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToArguments" {
            if let fact = sender as? Fact {
                if let argumentVC = segue.destination as? FactParentContainerViewController {
                    argumentVC.fact = fact
                }
                
            }
        }
        
        if segue.identifier == "toNewArgumentSegue" {
            if let navCon = segue.destination as? UINavigationController {
                if let newFactVC = navCon.topViewController as? NewFactViewController {
                    newFactVC.new = .fact
                }
            }
        }
    }

    @IBAction func infoButtonTapped(_ sender: Any) {
    }
}

class FactCell:UICollectionViewCell {
    @IBOutlet weak var factCellLabel: UILabel!
    @IBOutlet weak var factCellImageView: UIImageView!
    @IBOutlet weak var gradientView: UIView!
}

class AddTopicCell: UICollectionViewCell {
    
}
