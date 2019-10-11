//
//  FactCollectionViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 21.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

private let reuseIdentifier = "FactCell"

protocol LinkFactWithPostDelegate {
    func selectedFact(fact: Fact)
}

class FactCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var infoButton: UIBarButtonItem!
    
    var facts = [Fact]()
    var filteredFacts = [Fact]()
    
    let db = Firestore.firestore()
    
    var addFactToPost = false
    var delegate: LinkFactWithPostDelegate?
    
    let collectionViewSpacing:CGFloat = 30
    let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        getFacts()
        setUpSearchController()
        
        if addFactToPost {
            self.setDismissButton()
        }
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
        
        self.view.activityStartAnimating()
    }
    
    func setDismissButton() {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = Constants.imagineColor
        button.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        button.setImage(UIImage(named: "Dismiss"), for: .normal)
        button.heightAnchor.constraint(equalToConstant: 23).isActive = true
        button.widthAnchor.constraint(equalToConstant: 23).isActive = true
        
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.leftBarButtonItem = barButton
    }
    
    @objc func dismissTapped() {
        self.dismiss(animated: true, completion: nil)
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
    
    func setUpSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Suche nach Fakten"
        
        self.navigationItem.searchController = searchController
        definesPresentationContext = true
        
    }

    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
  


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if isFiltering {
            return filteredFacts.count
        }
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
        
        var fact: Fact?
        
        if isFiltering {
            fact = filteredFacts[indexPath.row]
        } else {
            fact = facts[indexPath.row]
        }
        
        if fact!.addMoreCell {
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
                
                
                cell.factCellLabel.text = fact!.title
                
                if let url = URL(string: fact!.imageURL) {
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
        
        var fact: Fact?
            
        if isFiltering {
            fact = filteredFacts[indexPath.row]
        } else {
            fact = facts[indexPath.row]
        }
        
        
        if fact!.addMoreCell {
            performSegue(withIdentifier: "toNewArgumentSegue", sender: nil)
        } else {
            if self.addFactToPost {
                self.setFactForPost(fact: fact!)
            } else {
                performSegue(withIdentifier: "goToArguments", sender: fact)
            }
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
        infoButton.showEasyTipView(text: Constants.texts.factOverviewText)
    }
    
    //MARK: LinkFactAndPost
    
    func setFactForPost(fact: Fact) {
        print("Set delegate")
        delegate?.selectedFact(fact: fact)
        self.dismiss(animated: true, completion: nil)
    }
    
    
    //MARK: -Search functionality
    
    var isSearchBarEmpty: Bool {
      return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText(_ searchText: String ){
        
        let titleRef = db.collection("Facts").whereField("name", isGreaterThan: searchText).whereField("name", isLessThan: "\(searchText)z").limit(to: 10)
        
        titleRef.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                self.filteredFacts.removeAll()
                for document in snap!.documents {
                    let documentData = document.data()
                    let documentID = document.documentID
                    
                    guard let name = documentData["name"] as? String,
                        let createTimestamp = documentData["createDate"] as? Timestamp,
                        let imageURL = documentData["imageURL"] as? String
                        
                        else {
                            continue
                    }
                    
                    let date = createTimestamp.dateValue()
                    let stringDate = date.formatRelativeString()
                    
                    let fact = Fact(addMoreDataCell: false)
                    fact.title = name
                    fact.createDate = stringDate
                    fact.documentID = documentID
                    fact.imageURL = imageURL
                    
                    self.filteredFacts.append(fact)
                }
                let fact = Fact(addMoreDataCell: true)
                self.filteredFacts.append(fact)
                self.collectionView.reloadData()
            }
        }
    }
    
    var isFiltering: Bool {
      return searchController.isActive && !isSearchBarEmpty
    }
}

extension FactCollectionViewController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    let searchBar = searchController.searchBar
    filterContentForSearchText(searchBar.text!)
  }
}

class FactCell:UICollectionViewCell {
    @IBOutlet weak var factCellLabel: UILabel!
    @IBOutlet weak var factCellImageView: UIImageView!
    @IBOutlet weak var gradientView: UIView!
}

class AddTopicCell: UICollectionViewCell {
    
}
