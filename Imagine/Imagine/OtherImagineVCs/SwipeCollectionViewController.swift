//
//  SwipeCollectionViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 07.07.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore

enum SwipeCollectionDiashow {
    case vision
    case intro
}


class SwipeCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, VisionPitchDelegate {
    
    var pictures: [UIImage] = [UIImage(named: "PitchSite0")!, UIImage(named: "PitchSite1")!, UIImage(named: "PitchSite2")!, UIImage(named: "PitchSite3")!, UIImage(named: "PitchSite4")!, UIImage(named: "PitchSite5")!, UIImage(named: "PitchSite6")!, UIImage(named: "PitchSite7")!]
    
    let green = UIColor(red:0.36, green:0.70, blue:0.37, alpha:1.0)
    private let reuseIdentifier = "VisionPitchCell"
    let appDel = UIApplication.shared.delegate as! AppDelegate
    
    var diashow: SwipeCollectionDiashow = .intro
    
    var communityVC: ImagineCommunityCollectionViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
        }
        collectionView.isPagingEnabled = true
        
        switch diashow {
        case .vision:
            appDel.myOrientation = .landscapeRight
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            UIView.setAnimationsEnabled(true)

        case .intro:
            let introPics = [UIImage(named: "Intro1")!, UIImage(named: "Intro2")!, UIImage(named: "Intro3")!, UIImage(named: "Intro4")!, UIImage(named: "Intro5")!, UIImage(named: "Intro6")!]
            
            self.pictures = introPics
        }
    }


    override func viewWillDisappear(_ animated: Bool) {
        
        if diashow == .vision {
            appDel.myOrientation = .portrait
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            UIView.setAnimationsEnabled(true)
        }
    }
    
    // MARK: UICollectionViewDataSource
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return pictures.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? VisionPitchCell {
            
            let picture = pictures[indexPath.row]
            cell.delegate = self
            
            if diashow == .intro {
                cell.dismissButton.isHidden = true
            }
            
            cell.pageControl.numberOfPages = pictures.count
            cell.pageControl.currentPage = indexPath.row
            
            cell.setIndexPath(indexPath: indexPath)
            cell.signUpButton.isHidden = true
            
            if indexPath.row == 0 { // First 
                cell.backButton.isEnabled = false
                cell.nextButton.isEnabled = true
                cell.nextButton.setTitleColor(.black, for: .normal)
                cell.backButton.setTitleColor(.gray, for: .normal)
                
            } else if indexPath.row == pictures.count-1 { //Last
                cell.backButton.isEnabled = true
                cell.nextButton.isEnabled = true
                if diashow == .intro {
                    cell.nextButton.setTitle("Start", for: .normal)
                    cell.signUpButton.isHidden = false
                } else {
                    cell.nextButton.setTitle(NSLocalizedString("done", comment: "done"), for: .normal)
                }
                cell.nextButton.setTitleColor(green, for: .normal)
                cell.backButton.setTitleColor(.black, for: .normal)
                
            } else {
                cell.backButton.isEnabled = true
                cell.nextButton.isEnabled = true
                cell.nextButton.setTitle(NSLocalizedString("next", comment: "next"), for: .normal)
                cell.nextButton.setTitleColor(.black, for: .normal)
                cell.backButton.setTitleColor(.black, for: .normal)
                
            }
            
            cell.pitchImageView.image = picture
            
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    func nextTapped(indexPath:IndexPath) {
        if indexPath.row != pictures.count {
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            
        } else {    // Last Picture
            
            if diashow == .intro {
                
                let defaults = UserDefaults.standard
                
                if let _ = defaults.string(forKey: "askedAboutCookies") {
                    self.dismiss(animated: true, completion: nil)
                } else {
                    let alert = UIAlertController(title: NSLocalizedString("cookie_alert_header", comment: "we have cookies"), message: NSLocalizedString("cookie_alert_description", comment: "what and how to change"), preferredStyle: .alert)
                    
                    alert.addAction(UIAlertAction(title: NSLocalizedString("cookie_alert_toEULA", comment: "to privacy policy"), style: .default, handler: { (_) in
                        let language = LanguageSelection().getLanguage()
                        if language == .german {
                            if let url = URL(string: "https://www.imagine.social/datenschutzerklaerung-app") {
                                UIApplication.shared.open(url)
                            }
                        } else {
                            if let url = URL(string: "https://en.imagine.social/datenschutzerklaerung-app") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }))
                    
                    alert.addAction(UIAlertAction(title: NSLocalizedString("cookie_alert_accept", comment: "accept cookies"), style: .default, handler: { (_) in
                        
                        defaults.set(true, forKey: "acceptedCookies")
                        defaults.set(true, forKey: "askedAboutCookies")
                        self.dismiss(animated: true, completion: nil)
                    }))
                    
                    alert.addAction(UIAlertAction(title: NSLocalizedString("cookie_alert_dontAccept", comment: "dont accept"), style: .cancel, handler: { (_) in
                        
                        //Already set to false
                        defaults.set(false, forKey: "acceptedCookies")
                        defaults.set(true, forKey: "askedAboutCookies")
                        self.dismiss(animated: true, completion: nil)
                    }))
                    
                    self.present(alert, animated: true, completion: nil)
                }
            } else {
                self.dismiss(animated: true) {
                    if let vc = self.communityVC {
                        vc.reloadViewForLayoutReason()
                    }
                }
            }
        }
        
    }
    
    func backTapped(indexPath:IndexPath) {
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    
    func signUpTapped() {
        if !AuthenticationManager.shared.isLoggedIn {
            performSegue(withIdentifier: "toLoginSegue", sender: nil)
        }
    }

    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.width, height: self.view.frame.height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    
    @IBAction func dismissButton(_ sender: Any) {
        self.dismiss(animated: true) {
            if let vc = self.communityVC {
                vc.reloadViewForLayoutReason()
            }
        }
    }
}
