//
//  SettingsLauncher.swift
//  Imagine
//
//  Created by Malte Schoppe on 14.07.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class Setting: NSObject {
    let settingType : SettingButtonType
    
    init(type: SettingButtonType) {
        self.settingType = type
    }
}

// Enum for the different Views that call the settingslauncher
enum SettingFor {
    case friendsTableView
    case profilePicture
    case userProfileOptions
}

// Enum for the different options that are displayer in the settingslauncher in the different views
enum SettingButtonType {
    case other
    case camera
    case photoLibrary
    case viewPicture
    case chatWithUser
    case blockUser
    case deleteFriend
    case cancel
}


//Wasn't aware of the UIAlertAction from below when I build this
class SettingsLauncher: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    //MARK:- Variables
    var FriendsTableVC:FriendsTableViewController?
    var userFeedVC: UserFeedTableViewController?
    
    let blackView = UIView()
    
    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = UIColor.clear
        return cv
    }()
    
    var friend:Friend?
    
    let cellId = "cellId"
    let settingCellHeight: CGFloat = 60
    
    var settings: [Setting] = {
        return [Setting(type: .cancel)]
    }()
    
    //MARK:- Initialization
    init(type: SettingFor) {
       super.init()
       
       switch type {
       case .friendsTableView:
           let friendsSettings: [Setting] = [Setting(type: .chatWithUser), Setting(type: .deleteFriend), Setting(type: .blockUser), Setting(type: .cancel)]
           self.settings = friendsSettings
       case .profilePicture:
           let profileSettings: [Setting] = [Setting(type: .viewPicture), Setting(type: .photoLibrary), Setting(type: .cancel)]
           self.settings = profileSettings
       case .userProfileOptions:
           let profileSettings: [Setting] = [Setting(type: .blockUser), Setting(type: .cancel)]
           self.settings = profileSettings
       }
       
       collectionView.dataSource = self
       collectionView.delegate = self
       
       collectionView.register(SelectionCell.self, forCellWithReuseIdentifier: cellId)
   }
    
    func showSettings(for friend: Friend?) {
        //show menu
        self.friend = friend
        
        if let window = UIApplication.keyWindow() {
            
            blackView.backgroundColor = UIColor(white: 0, alpha: 0.5)
            
            blackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDismiss)))
            
            window.addSubview(blackView)
            
            window.addSubview(collectionView)
            
            let height: CGFloat = CGFloat(settings.count) * settingCellHeight
            let y = window.frame.height - height-10
            collectionView.frame = CGRect(x: 0, y: window.frame.height, width: window.frame.width-20, height: height)
            collectionView.layer.cornerRadius = 10
            
            
            blackView.frame = window.frame
            blackView.alpha = 0
            
            collectionView.reloadData()
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                self.blackView.alpha = 1
                // x = 10 so it is in the middle of the window (width is set to window width -20 in the code above
                self.collectionView.frame = CGRect(x:10, y: y, width: self.collectionView.frame.width, height: self.collectionView.frame.height)
                
            }, completion: nil)
        }
    }
    
    @objc func handleDismiss(setting: Setting) {    // Not just dismiss but also the presented options
        UIView.animate(withDuration: 0.5, animations: {
            self.blackView.alpha = 0
            
            if let window = UIApplication.keyWindow() {
                self.collectionView.frame = CGRect(x: 10, y: window.frame.height, width: self.collectionView.frame.width, height: self.collectionView.frame.height)
            }
        }, completion: { (_) in
            switch setting.settingType {
            case .cancel:
                print("Just dismiss it")
            default:
                if let friend = self.friend {
                    self.FriendsTableVC?.showControllerForSetting(setting: setting, friend: friend)
                } else {
                    self.userFeedVC?.profilePictureSettingTapped(setting: setting)
                }
            }

        })
    }
    
    //MARK:- CollectionView
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let setting = self.settings[indexPath.item]
        handleDismiss(setting: setting)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return settings.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! SelectionCell
        
        let setting = settings[indexPath.item]
        cell.setting = setting
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: settingCellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
}

